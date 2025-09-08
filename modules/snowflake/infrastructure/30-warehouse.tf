// Warehouses are driven by var.warehouses. To add a new one:
// - Add a new key (e.g., "ad_hoc") under var.warehouses with size/comment
// - Add technical role keys to grantees in that map to grant USAGE/MONITOR (see 30a-grants-warehouse-to-technical-role.tf)
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
