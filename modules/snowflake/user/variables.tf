variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# technical_roles: output from account_role module
variable "technical_roles" {
  description = "Map of logical key → account role name (technical)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# business_roles: output from account_role module
variable "business_roles" {
  description = "Map of logical key → account role name (business)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# warehouses: output from warehouse module
variable "warehouses" {
  description = "Map of logical key → warehouse name"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# databases: output from database module
variable "databases" {
  description = "Map of logical key → database name"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# service_users:
#   dbt:
#     name_prefix:      DBT_SERVICE_USER
#     role:             transform        # key into technical_roles
#     warehouse:        transform        # key into warehouses
#     default_database: silver           # key into databases
#     email:            ""
#     login_name:       ""
#     display_name:     ""
#     disabled:         false
variable "service_users" {
  description = "Service users to create"
  type = map(object({
    name_prefix      = string
    role             = string           # technical_roles key
    warehouse        = optional(string) # warehouses key
    default_database = optional(string) # databases key
    email            = optional(string)
    login_name       = optional(string)
    display_name     = optional(string)
    disabled         = optional(bool, false)
    default_secondary_roles_option = optional(string, "ALL")
  }))
  default = {}
}

# RSA public key PEM per service user key
# Generated manually: openssl genrsa 4096 | openssl rsa -pubout
# Stored in secrets/dev.yaml (SOPS encrypted)
variable "service_user_public_keys" {
  description = "Map of service user key → RSA public key PEM"
  type        = map(string)
  default     = {}
}

# human_user_role_grants:
#   BUSINESS_USER_ANALYTICS_ENGINEER: [analytics_engineer]
#   BUSINESS_USER_DATA_ENGINEER:      [data_engineer]
variable "human_user_role_grants" {
  description = "Map of existing Snowflake username → list of business role keys to grant"
  type        = map(list(string))
  default     = {}
}

# managed_human_users: users that Terraform creates (Okta SSO auth — no password/MFA).
# role: single business role key to grant after creation.
#
# human_users:
#   BUSINESS_USER_ANALYTICS_ENGINEER:
#     display_name: "Analytics Engineer"
#     email: null
#     login_name: null
#     default_role: PUBLIC
#     role: analytics_engineer
variable "managed_human_users" {
  description = "Human users to create in Snowflake (Okta-managed auth). Role assigned after creation."
  type = map(object({
    display_name = optional(string)
    email        = optional(string)
    login_name   = optional(string)
    default_role = optional(string, "PUBLIC")
    role         = string # business_roles key
    disabled     = optional(bool, false)
    query_tag    = optional(string)
  }))
  default = {}
}
