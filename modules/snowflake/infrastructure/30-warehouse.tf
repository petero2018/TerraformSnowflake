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


resource "snowflake_warehouse" "ingestion_wh" {
  provider       = snowflake.sysadmin
  name           = "INGESTION_WH_${var.snowflake_env}"
  warehouse_size = "SMALL"

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  comment = "The Ingestion Warehouse is used by external ingestion tools and processes."

}

resource "snowflake_warehouse" "reporting_wh" {
  provider       = snowflake.sysadmin
  name           = "REPORTING_WH_${var.snowflake_env}"
  warehouse_size = "MEDIUM"

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  comment = "The Reporting Warehouse is used by external reporting and analytics tools and processes."

}


resource "snowflake_warehouse" "retl_wh" {
  provider       = snowflake.sysadmin
  name           = "RETL_WH_${var.snowflake_env}"
  warehouse_size = "SMALL"

  auto_suspend                 = 60
  auto_resume                  = true
  initially_suspended          = true
  statement_timeout_in_seconds = 7200

  comment = "The rETL Warehouse is used by external tools and processes for rETL operations."

}