variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# database_roles: output from database_role module (standard_database_roles)
# { "bronze|R": { name: "...", fully_qualified_name: "..." }, ... }
variable "database_roles" {
  description = "Map of '<db_key>|<kind>' → database role attributes"
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
#     bronze: RW
#     silver: RW
#     gold:   RW
variable "technical_role_grants" {
  description = "Map of technical role key → { db_key: kind } database access grants"
  type        = map(map(string))
  default     = {}
}

# business_role_grants:
#   analytics_engineer:
#     gold: R
variable "business_role_grants" {
  description = "Map of business role key → { db_key: kind } database access grants"
  type        = map(map(string))
  default     = {}
}
