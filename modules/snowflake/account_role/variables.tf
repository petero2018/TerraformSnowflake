variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# technical_roles:
#   transform:
#     comment: "dbt workloads"
#     super_admin_roles: [SYSADMIN]   # omit = [SYSADMIN]; [] = no parent grant
variable "technical_roles" {
  description = "Technical account roles to create. Name pattern: TECHNICAL_ACCOUNT_ROLE_<KEY>_<ENV>"
  type = map(object({
    comment           = optional(string, "")
    super_admin_roles = optional(list(string))
  }))
  default = {}
}

# business_roles:
#   analytics_engineer:
#     comment: "Human analytics engineer"
#     super_admin_roles: [SYSADMIN]
variable "business_roles" {
  description = "Business account roles to create. Name pattern: BUSINESS_ACCOUNT_ROLE_<KEY>_<ENV>"
  type = map(object({
    comment           = optional(string, "")
    super_admin_roles = optional(list(string))
  }))
  default = {}
}
