// Database-level grants:
// - RW roles get ALL privileges on the database
// - R roles get USAGE only
resource "snowflake_grant_privileges_to_database_role" "db_grants_all" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if v.all_privs }
  database_role_name = local.db_roles[each.key].fully_qualified_name
  on_database        = snowflake_database.databases[each.value.db_key].name
  with_grant_option  = false

  all_privileges = true
}

resource "snowflake_grant_privileges_to_database_role" "db_grants_usage" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if !v.all_privs }
  database_role_name = local.db_roles[each.key].fully_qualified_name
  on_database        = snowflake_database.databases[each.value.db_key].name
  with_grant_option  = false

  privileges = ["USAGE"]
}
