output "database_roles" {
  description = "Map of '<db_key>|<ROLE_KEY>' → database role attributes"
  value = {
    for key, r in local.all_db_roles :
    key => {
      name                 = r.name
      database             = r.database
      fully_qualified_name = r.fully_qualified_name
    }
  }
}
