resource "snowflake_database" "bronze_db" {
  provider = snowflake.sysadmin
  name     = "BRONZE_${var.snowflake_env}"
  comment  = "The Bronze Layer is where we land all the data from external source systems. The table structures in this layer correspond to the source system table structures 'as-is,' along with any additional metadata columns that capture the load date/time, process ID, etc."
}

resource "snowflake_database" "silver_db" {
  provider = snowflake.sysadmin
  name     = "SILVER_${var.snowflake_env}"
  comment  = "The Silver layer is where we apply standardisation to our source datasets. This standardisation aligns field names across sources, applies common data cleaning operations and organises the data into a well known structure."
}

resource "snowflake_database" "gold_db" {
  provider = snowflake.sysadmin
  name     = "GOLD_${var.snowflake_env}"
  comment  = "The Gold layer is for reporting and uses more de-normalized and read-optimized data models with fewer joins. The final layer of data transformations and data quality rules are applied here."
}

resource "snowflake_database" "operations_db" {
  provider = snowflake.sysadmin
  name     = "OPERATION_${var.snowflake_env}"
  comment  = "This database is designed to store dbt operation materialised data."
}

