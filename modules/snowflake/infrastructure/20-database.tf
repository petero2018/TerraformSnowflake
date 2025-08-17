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

resource "snowflake_database" "legacy_db" {
  provider = snowflake.sysadmin
  name     = "LEGACY_${var.snowflake_env}"
  comment  = "This database is designed to separate legacy data from newly ingested data."
}

resource "snowflake_database" "segment_db" {
  provider = snowflake.sysadmin
  name     = "SEGMENT_${var.snowflake_env}"
  comment  = "This database is dedicated for Segment data"
}

resource "snowflake_database" "kafka_db" {
  provider = snowflake.sysadmin
  name     = "KAFKA_${var.snowflake_env}"
  comment  = "This database is dedicated for Kafka data"
}

resource "snowflake_database" "sandbox_db" {
  provider = snowflake.sysadmin
  name     = "SANDBOX_${var.snowflake_env}"
  comment  = "A dedicated environment for executing ad-hoc SQL queries and experimenting safely without impacting production or development data."
}

resource "snowflake_database" "dbt_development_db" {
  provider = snowflake.sysadmin
  name     = "DBT_DEVELOPMENT_DB_${var.snowflake_env}"
  comment  = "Database is for local dbt code run"
}

resource "snowflake_database" "restricted_db" {
  provider = snowflake.sysadmin
  name     = "RESTRICTED_${var.snowflake_env}"
  comment  = "A storage solution dedicated to hosting sensitive data, with access restricted to selected individuals."
}

resource "snowflake_database" "post_curation_db" {
  provider = snowflake.sysadmin
  name     = "POST_CURATION_${var.snowflake_env}"
  comment  = "Storage for teams to engineer data post curation."
}
