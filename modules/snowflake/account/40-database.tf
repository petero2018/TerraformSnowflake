resource "snowflake_database" "snowflake_settings_db" {
  name    = "SNOWFLAKE_SETTINGS"
  comment = "Database to store shared snowflake resources e.g. network rules"
}

resource "snowflake_schema" "network_rules_schema" {
  name     = "NETWORK_RULES"
  database = snowflake_database.snowflake_settings_db.name

  is_transient        = false
  with_managed_access = false
}
