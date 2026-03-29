resource "snowflake_warehouse" "warehouses" {
  provider = snowflake.sysadmin
  for_each = var.warehouses

  name           = "${upper(each.key)}_${var.snowflake_env}"
  warehouse_size = each.value.size
  comment        = each.value.comment

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  lifecycle {
    ignore_changes = [max_concurrency_level]
  }
}
