
variable "users" {
  type = list(object({
    name                    = string
    email                   = optional(string)
    default_role            = string
    default_namespace       = optional(string)
    default_warehouse       = optional(string)
    enabled                 = optional(bool, true)
    default_secondary_roles = optional(string, "ALL")
    extra_roles             = optional(list(string), [])
    system_role             = optional(string, null)
    is_orgadmin             = optional(bool, false)
  }))
  description = "Business users to be created in the Snowflake account"

  validation {
    condition = alltrue([
      for user in var.users : contains([
        "ACCOUNTADMIN",
        "SECURITYADMIN",
        "SYSADMIN",
        "USERADMIN"
      ], user.system_role) if user.system_role != null
    ])
    error_message = "Invalid system role specified for user. Valid roles are ACCOUNTADMIN, SECURITYADMIN, SYSADMIN, USERADMIN or null."
  }
}
