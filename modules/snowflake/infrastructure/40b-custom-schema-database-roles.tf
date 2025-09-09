// Custom database roles with explicit schema-object grants, not assigned by default.
locals {
  custom_schema_roles_flat = {
    for r in flatten([
      for db_key, roles in var.custom_schema_roles : [
        for rk, rc in roles : {
          id        = "${db_key}|${rk}"
          db_key    = db_key
          role_key  = rk
          name      = coalesce(rc.name, "ROLE_${upper(db_key)}_${var.snowflake_env}_${upper(rk)}")
          comment   = try(rc.comment, null)
          grants    = try(rc.grants, [])
        }
      ]
    ]) : r.id => r
  }

  csr_grants_expanded = {
    for g in flatten([
      for id, r in local.custom_schema_roles_flat : [
        for grant in r.grants : [
          for ot in (grant.object_type == "*" ? local.object_types : [grant.object_type]) : {
            id         = "${id}|${ot}|${lower(grant.schema == null ? "" : grant.schema)}|${lower(grant.scope == null ? "all" : grant.scope)}|${tostring(coalesce(grant.all_privileges, false))}"
            role_id    = id
            db_key     = r.db_key
            object     = ot
            scope      = grant.scope == null ? "all" : grant.scope
            schema     = grant.schema
            all_privs  = coalesce(grant.all_privileges, false)
            privileges = try(grant.privileges, null)
          }
        ]
      ]
    ]) : g.id => g
  }
}

resource "snowflake_database_role" "custom_schema_roles" {
  provider = snowflake.sysadmin
  for_each = local.custom_schema_roles_flat

  database = snowflake_database.databases[each.value.db_key].fully_qualified_name
  name     = each.value.name
  comment  = each.value.comment
}

// DB-scope: grant all schemaObjectPrivileges
resource "snowflake_grant_privileges_to_database_role" "csr_all_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.csr_grants_expanded : k => v if v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.custom_schema_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false

  all_privileges = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
  }
}

// Schema-scope: grant all schemaObjectPrivileges
resource "snowflake_grant_privileges_to_database_role" "csr_all_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.csr_grants_expanded : k => v if v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.custom_schema_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false

  all_privileges = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}

// DB-scope: explicit privileges
resource "snowflake_grant_privileges_to_database_role" "csr_privs_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.csr_grants_expanded : k => v if !v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.custom_schema_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false

  privileges = coalesce(
    each.value.privileges,
    lookup(local.object_read_privileges, each.value.object, ["SELECT"]) 
  )

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
  }
}

// Schema-scope: explicit privileges
resource "snowflake_grant_privileges_to_database_role" "csr_privs_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.csr_grants_expanded : k => v if !v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.custom_schema_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false

  privileges = coalesce(
    each.value.privileges,
    lookup(local.object_read_privileges, each.value.object, ["SELECT"]) 
  )

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}

