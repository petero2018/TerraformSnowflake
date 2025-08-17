resource "snowflake_account_parameter" "week_start" {
  provider = snowflake.accountadmin
  key      = "WEEK_START"
  value    = "7"
}
