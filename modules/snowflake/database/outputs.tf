output "databases" {
  description = "Map of logical key → Snowflake database attributes"
  value = {
    for key, db in snowflake_database.databases :
    key => {
      name                = db.name
      fully_qualified_name = db.fully_qualified_name
    }
  }
}
