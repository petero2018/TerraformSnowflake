resource "snowflake_warehouse" "transform_wh" {
  provider       = snowflake.sysadmin
  name           = "TRANSFORM_WH_${var.snowflake_env}"
  warehouse_size = "SMALL"

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  comment = "The Transform Warehouse is used by external transformation tools. Unlike ingestion tools, these external tools may not have their own scalable functionality. Therefore, a burstable larger warehouse size might be required as demand increases."

}
