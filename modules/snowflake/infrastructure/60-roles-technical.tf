resource "snowflake_account_role" "transform_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_TRANSFORM_${var.snowflake_env}"
}

resource "snowflake_grant_account_role" "transform_role" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.transform_role.name
  parent_role_name = "SYSADMIN"
}
