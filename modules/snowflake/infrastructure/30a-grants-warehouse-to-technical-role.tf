resource "snowflake_grant_privileges_to_account_role" "warehouse_usage_monitors" {
  provider          = snowflake.securityadmin
  for_each          = local.warehouse_grants
  account_role_name = local.technical_roles[each.value.grantee]

  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.warehouses[each.value.wh_key].name
  }
}
