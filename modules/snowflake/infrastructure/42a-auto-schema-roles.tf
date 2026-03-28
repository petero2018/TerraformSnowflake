// Auto-create six custom database roles for schema-level grants per core DB (bronze/silver/gold):
// - DATABASE_ROLE_<DB>_<ENV>_SCHEMA_R and DATABASE_ROLE_<DB>_<ENV>_SCHEMA_RW
// - Grant these custom roles to the corresponding base DB roles (ROLE_<DB>_<ENV>_R/RW)
// - Apply schema-level privileges across all configured schemas under that DB
//
// This ensures no RBAC gap: anyone with the base DB role also inherits the schema-level privileges.

locals {
  core_schema_dbs = ["bronze", "silver", "gold"]

  // Determine which core DBs have schemas configured
  schema_dbs_present = [for k in local.core_schema_dbs : k if contains(keys(var.schemas), k)]

  // Define the two custom roles per DB
  auto_schema_roles = {
    for id, cfg in {
      for db in local.schema_dbs_present : db => {
        r  = "DATABASE_ROLE_${upper(db)}_${var.snowflake_env}_SCHEMA_R"
        rw = "DATABASE_ROLE_${upper(db)}_${var.snowflake_env}_SCHEMA_RW"
      }
    } :
    id => cfg
  }

  // Flatten roles for resource creation
  auto_schema_roles_flat = {
    for item in flatten([
      for db, names in local.auto_schema_roles : [
        { id = "${db}|R",  db = db, name = names.r  },
        { id = "${db}|RW", db = db, name = names.rw },
      ]
    ]) : item.id => item
  }

  // Defaults if not provided via var.schema_role_privileges
  default_schema_privs_by_kind = {
    R  = ["USAGE"]
    RW = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  }

  // Merge YAML-provided privileges per DB with defaults
  schema_privs_by_db_kind = {
    for db in local.schema_dbs_present :
    db => {
      R  = try(var.schema_role_privileges[db].R,  local.default_schema_privs_by_kind.R)
      RW = try(var.schema_role_privileges[db].RW, local.default_schema_privs_by_kind.RW)
    }
  }

  // For each custom role, generate a grant entry per schema defined under that DB
  auto_schema_role_schema_grants = {
    for g in flatten([
      for key, role in local.auto_schema_roles_flat : [
        for sch in lookup(var.schemas, role.db, []) : {
          id         = "${role.db}|${role.name}|${sch.name}"
          db         = role.db
          role_key   = key
          role_name  = role.name
          kind       = element(split("|", key), 1)
          schema     = sch.name
          privileges = local.schema_privs_by_db_kind[role.db][element(split("|", key), 1)] // R or RW
        }
      ]
    ]) : g.id => g
  }
}

// Create custom schema roles as database roles
resource "snowflake_database_role" "auto_schema_roles" {
  provider = snowflake.sysadmin
  for_each = local.auto_schema_roles_flat

  database = snowflake_database.databases[each.value.db].fully_qualified_name
  name     = each.value.name
}

// Grant custom role to the corresponding base DB role (no RBAC gap)
resource "snowflake_grant_database_role" "auto_custom_to_base" {
  provider           = snowflake.securityadmin
  for_each           = local.auto_schema_roles_flat

  database_role_name = snowflake_database_role.auto_schema_roles[each.key].fully_qualified_name
  // Parent is the base DB role created elsewhere
  parent_database_role_name = local.db_roles[each.key].fully_qualified_name
}

// Apply schema-level privileges for each schema under the DB
resource "snowflake_grant_privileges_to_database_role" "auto_schema_role_schema_privs" {
  provider           = snowflake.securityadmin
  for_each           = local.auto_schema_role_schema_grants

  database_role_name = snowflake_database_role.auto_schema_roles[each.value.role_key].fully_qualified_name

  privileges        = each.value.privileges
  with_grant_option = false

  on_schema {
    schema_name = snowflake_schema.schemas["${each.value.db}|${each.value.schema}"].fully_qualified_name
  }
}
