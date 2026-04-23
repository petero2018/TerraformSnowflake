output "accounts" {
  description = "Created Snowflake accounts keyed by account key."
  value = {
    for k, a in snowflake_account.accounts : k => {
      name                 = a.name
      fully_qualified_name = a.fully_qualified_name
      organization_name    = a.organization_name
    }
  }
}
