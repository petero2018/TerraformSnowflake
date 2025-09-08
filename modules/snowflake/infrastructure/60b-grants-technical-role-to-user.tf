resource "snowflake_grant_account_role" "user_transform_technical_role" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.transform_technical_role.name
  user_name = "DBT_USER"

}
