output "technical_roles" {
  description = "Map of logical key → Snowflake account role attributes"
  value = {
    for key, r in snowflake_account_role.technical :
    key => {
      name                 = r.name
      fully_qualified_name = r.fully_qualified_name
    }
  }
}

output "business_roles" {
  description = "Map of logical key → Snowflake account role attributes"
  value = {
    for key, r in snowflake_account_role.business :
    key => {
      name                 = r.name
      fully_qualified_name = r.fully_qualified_name
    }
  }
}
