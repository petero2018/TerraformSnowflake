variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV, PROD, or empty string for global stacks."
  default     = ""
  validation {
    condition     = contains(["DEV", "PROD", ""], var.snowflake_env)
    error_message = "snowflake_env must be DEV, PROD, or empty string."
  }
}

# database_roles: output from database_role module
# { "bronze|READ": { name: "...", fully_qualified_name: "..." }, ... }
variable "database_roles" {
  description = "Map of '<db_key>|<role_key>' → database role attributes"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
}

# technical_roles: output from account_role module
# { transform: { name: "TECHNICAL_ACCOUNT_ROLE_TRANSFORM_DEV", ... }, ... }
variable "technical_roles" {
  description = "Map of logical key → account role attributes (technical)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# business_roles: output from account_role module
# { analytics_engineer: { name: "BUSINESS_ACCOUNT_ROLE_ANALYTICS_ENGINEER_DEV", ... }, ... }
variable "business_roles" {
  description = "Map of logical key → account role attributes (business)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# Grants from account_roles YAML: database_access per role
# technical_role_grants:
#   transform:
#     bronze: READ_WRITE
#     gold:   REPORTING_R   ← any role_key from database_roles.yaml
variable "technical_role_grants" {
  description = "Map of technical role key → { db_key: db_role_key } database access grants"
  type        = map(map(string))
  default     = {}
}

# business_role_grants:
#   analytics_engineer:
#     gold: READ
variable "business_role_grants" {
  description = "Map of business role key → { db_key: db_role_key } database access grants"
  type        = map(map(string))
  default     = {}
}

# Direct grants: exact Snowflake account role name → { db_key: role_key }
# Used for global stacks where account role outputs are not available.
# grants:
#   SYSADMIN:
#     account_admin: READ
variable "grants" {
  description = "Map of exact account role name → { db_key: db_role_key } — for global/agnostic role grants"
  type        = map(map(string))
  default     = {}
}
