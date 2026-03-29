output "service_users" {
  description = "Map of logical key → Snowflake service user attributes"
  value = {
    for key, u in snowflake_user.service_users :
    key => {
      name                 = u.name
      fully_qualified_name = u.fully_qualified_name
    }
  }
}
