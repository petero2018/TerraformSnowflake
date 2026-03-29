output "database_roles" {
  description = "Map of '<db_key>|<kind>' → database role attributes (standard + custom)"
  value = {
    for key, r in local.all_db_roles :
    key => {
      name                 = r.name
      database             = r.database
      fully_qualified_name = r.fully_qualified_name
    }
  }
}

output "standard_database_roles" {
  description = "Standard R/RW database roles only — used for account role grants"
  value = {
    for key, r in local.standard_db_roles :
    key => {
      name                 = r.name
      database             = r.database
      fully_qualified_name = r.fully_qualified_name
    }
  }
}
