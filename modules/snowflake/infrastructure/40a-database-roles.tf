// Creates DATABASE_ROLE_<DB>_<ENV>_R and DATABASE_ROLE_<DB>_<ENV>_RW based on var.databases[*].roles.
// Add/remove kinds ("R"/"RW") per database in var.databases to change what gets created.
resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = local.role_matrix
  database = snowflake_database.databases[each.value.db_key].fully_qualified_name
  name     = each.value.role_name
}
