resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = local.role_matrix
  database = snowflake_database.databases[each.value.db_key].fully_qualified_name
  name     = each.value.role_name
}
