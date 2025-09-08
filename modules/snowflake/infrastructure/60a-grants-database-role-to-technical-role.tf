resource "snowflake_grant_database_role" "db_role_to_tech" {
  provider           = snowflake.securityadmin
  for_each           = local.technical_db_role_grants
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  parent_role_name   = snowflake_account_role.technical_roles[each.value.tr_key].name
}
