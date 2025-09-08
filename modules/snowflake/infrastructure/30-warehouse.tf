resource "snowflake_warehouse" "warehouses" {
  provider       = snowflake.sysadmin
  for_each       = local.whs
  name           = each.value.name
  warehouse_size = each.value.warehouse_size

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  comment = each.value.comment
}
