// Creates DATABASE_ROLE_<DB>_<ENV>_R and DATABASE_ROLE_<DB>_<ENV>_RW based on var.databases[*].roles.
// Add/remove kinds ("R"/"RW") per database in var.databases to change what gets created.
//
// Two resource blocks handle the prevent_destroy lifecycle flag, which cannot be dynamic in Terraform:
//   - db_roles      (active in DEV):  prevent_destroy = false — allows full teardown
//   - db_roles_prod (active in PROD): prevent_destroy = true  — guards against accidental deletion
//
// All other files reference local.db_roles which merges whichever resource is active.

resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env == "PROD" ? {} : local.role_matrix

  database = try(
    snowflake_database.databases[each.value.db_key].fully_qualified_name,
    "${upper(each.value.db_key)}_${var.snowflake_env}"
  )
  name = each.value.role_name

  lifecycle {
    prevent_destroy = false
  }
}

resource "snowflake_database_role" "db_roles_prod" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env == "PROD" ? local.role_matrix : {}

  database = try(
    snowflake_database.databases[each.value.db_key].fully_qualified_name,
    "${upper(each.value.db_key)}_${var.snowflake_env}"
  )
  name = each.value.role_name

  lifecycle {
    prevent_destroy = true
  }
}

// Unified lookup used by all downstream resources — merge whichever resource is active.
locals {
  db_roles = merge(
    snowflake_database_role.db_roles,
    snowflake_database_role.db_roles_prod,
  )
}

// Grant database roles to configured super-admin roles (default SYSADMIN)
resource "snowflake_grant_database_role" "db_role_to_super_admins" {
  provider           = snowflake.securityadmin
  for_each           = local.db_role_super_admin_bindings
  database_role_name = local.db_roles[each.value.pair].fully_qualified_name
  parent_role_name   = each.value.admin
}
