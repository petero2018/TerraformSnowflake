output "schemas" {
  description = "Map of '<db_key>__<schema_name>' → Snowflake schema attributes"
  value = {
    for key, s in snowflake_schema.schemas :
    key => {
      database             = s.database
      name                 = s.name
      fully_qualified_name = s.fully_qualified_name
    }
  }
}
