resource "snowflake_account_role" "transform_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_TRANSFORM_${var.snowflake_env}"
}
