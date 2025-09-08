resource "snowflake_grant_account_role" "user_transform_technical_role" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.technical_roles["transform"].name
  user_name = "DBT_USER"
}
