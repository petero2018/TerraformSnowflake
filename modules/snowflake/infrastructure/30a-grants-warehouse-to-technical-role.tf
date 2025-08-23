resource "snowflake_grant_privileges_to_account_role" "grant_warehouse_usage_to_transform_role" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transform_role.name

  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.transform_wh.name
  }
}
