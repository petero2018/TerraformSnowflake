variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV, PROD, or empty string for global stacks."
  default     = ""
  validation {
    condition     = contains(["DEV", "PROD", ""], var.snowflake_env)
    error_message = "snowflake_env must be DEV, PROD, or empty string."
  }
}

# Valid database keys from databases.yaml — used to compute Snowflake names and filter.
variable "valid_database_keys" {
  description = "List of valid database keys (from databases.yaml)."
  type        = list(string)
  default     = []
}

# Name overrides: database key → override base name before uppercasing.
variable "name_overrides" {
  description = "Map of database key → override name (before uppercasing and env suffix)."
  type        = map(string)
  default     = {}
}

# Per-database role config from database_roles.yaml — used to compute role names and FQNs.
# Only profile and role_name are needed here (privilege details belong to the database_role module).
variable "db_role_config" {
  description = "Per-database role definitions — used to compute database role FQNs from keys."
  type = map(object({         # key = database_key
    roles = map(object({      # key = role_key (READ, READ_WRITE, REPORTING_R, ...)
      profile   = optional(string)  # profile name → used in generated role name (e.g. R_DEFAULT)
      role_name = optional(string)  # override → used as-is in FQN
    }))
  }))
  default = {}
}

# Grant maps from account_roles YAML: database_access per role (already resolved to flat string per env)
# technical_role_grants:
#   transform:
#     bronze: READ
#     silver: READ_WRITE
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
# Used for global/agnostic stacks (e.g. SYSADMIN → account_admin: READ).
variable "grants" {
  description = "Map of exact account role name → { db_key: db_role_key } — for global/agnostic role grants"
  type        = map(map(string))
  default     = {}
}
