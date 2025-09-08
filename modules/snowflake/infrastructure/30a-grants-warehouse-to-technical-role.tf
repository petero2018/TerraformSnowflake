resource "snowflake_grant_privileges_to_account_role" "grant_warehouse_usage_to_transform_technical_role" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transform_technical_role.name

  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.transform_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_warehouse_usage_to_ingestion_technical_role" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.ingestion_technical_role.name

  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ingestion_wh.name
  }
}



resource "snowflake_grant_privileges_to_account_role" "grant_warehouse_usage_to_reporting_technical_role" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.reporting_technical_role.name

  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.reporting_wh.name
  }
}
