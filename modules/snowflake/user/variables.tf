variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# Valid database keys — used to compute default_namespace for service users.
variable "valid_database_keys" {
  description = "List of valid database keys from databases.yaml."
  type        = list(string)
  default     = []
}

# Name overrides: database key → Snowflake base name.
variable "name_overrides" {
  description = "Map of database key → override name (before uppercasing and env suffix)."
  type        = map(string)
  default     = {}
}

# service_users:
#   dbt:
#     name_prefix:      SERVICE_USER_DBT
#     role:             transform        # key into technical_roles
#     warehouse:        transform        # key into warehouses
#     default_database: silver           # key into databases
#     email:            ""
#     login_name:       ""
#     display_name:     ""
#     disabled:         false
#
# query_tag is auto-computed as "svc_<name_prefix>" — not configurable per user
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
    disabled           = optional(bool, false)
    network_policy_key = optional(string) # key into svc_user_network_policies; env suffix appended by module
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
# human_user_role_grants: grants for pre-existing users not managed by Terraform
variable "human_user_role_grants" {
  description = "Map of existing Snowflake username -> list of business role keys to grant"
  type        = map(list(string))
  default     = {}
}

variable "business_roles_dev" {
  description = "Deprecated — computed from role key. Kept for backwards compat, ignored if empty."
  type        = map(any)
  default     = {}
}

variable "business_roles_prod" {
  description = "Deprecated — computed from role key. Kept for backwards compat, ignored if empty."
  type        = map(any)
  default     = {}
}

# managed_human_users: users that Terraform creates (Okta SSO auth).
# grant_envs: ["dev"], ["prod"], or ["dev", "prod"]
variable "managed_human_users" {
  description = "Human users to create in Snowflake (Okta-managed auth). Role assigned after creation."
  type = map(object({
    display_name = optional(string)
    email        = optional(string)
    login_name   = optional(string)
    default_role = optional(string, "PUBLIC")
    role         = string
    grant_envs   = optional(list(string), [])
    disabled     = optional(bool, false)
    query_tag    = optional(string)
  }))
  default = {}
}
