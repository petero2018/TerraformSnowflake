// Creates DATABASE_ROLE_<DB>_<ENV>_R and DATABASE_ROLE_<DB>_<ENV>_RW based on var.databases[*].roles.
// Add/remove kinds ("R"/"RW") per database in var.databases to change what gets created.
resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = local.role_matrix

  # Decouple from managed database resources: if the DB is not tracked in Terraform,
  # fall back to the expected database name (<PREFIX>_<ENV>), which must exist in Snowflake.
  database = try(
    snowflake_database.databases[each.value.db_key].fully_qualified_name,
    "${upper(each.value.db_key)}_${var.snowflake_env}"
  )
  name     = each.value.role_name

  lifecycle {
    # Safety: avoid accidental deletion of roles if config changes abruptly
    prevent_destroy = true
  }
}

// Grant database roles to configured super-admin roles (default SYSADMIN)
resource "snowflake_grant_database_role" "db_role_to_super_admins" {
  provider           = snowflake.securityadmin
  for_each           = local.db_role_super_admin_bindings
  database_role_name = snowflake_database_role.db_roles[each.value.pair].fully_qualified_name
  parent_role_name   = each.value.admin
}
