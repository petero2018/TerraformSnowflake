resource "snowflake_warehouse" "warehouses" {
  provider = snowflake.sysadmin
  for_each = var.warehouses

  name           = "${upper(each.key)}_${var.snowflake_env}"
  warehouse_size = each.value.size
  comment        = each.value.comment
  warehouse_type = each.value.warehouse_type

  auto_suspend                        = each.value.auto_suspend
  auto_resume                         = each.value.auto_resume
  initially_suspended                 = each.value.initially_suspended
  statement_timeout_in_seconds        = each.value.statement_timeout_in_seconds

  # Multi-cluster settings — only set if provided
  max_cluster_count = each.value.max_cluster_count
  min_cluster_count = each.value.min_cluster_count
  scaling_policy    = each.value.scaling_policy

  # Concurrency / queue settings — only set if provided
  max_concurrency_level               = each.value.max_concurrency_level
  statement_queued_timeout_in_seconds = each.value.statement_queued_timeout_in_seconds

  lifecycle {
    ignore_changes = [max_concurrency_level]
  }
}
