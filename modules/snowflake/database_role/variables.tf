variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV, PROD, or empty string for env-agnostic (global) databases."
  default     = ""
  validation {
    condition     = contains(["DEV", "PROD", ""], var.snowflake_env)
    error_message = "snowflake_env must be DEV, PROD, or empty string."
  }
}

# Valid database keys from databases.yaml — used to compute Snowflake database names
# and to validate that database_role_config only references known databases.
variable "valid_database_keys" {
  description = "List of valid database keys from databases.yaml. Used for name computation and validation."
  type        = list(string)
}

# Name overrides: maps a database key to a different base name before uppercasing.
# e.g. { operations = "OPERATION" } → "operations" → "OPERATION_DEV" instead of "OPERATIONS_DEV"
variable "name_overrides" {
  description = "Map of database key → override name (before uppercasing and env suffix)."
  type        = map(string)
  default     = {}
}

# Shared privilege profiles — reusable by name in database_role_config.
# Each profile defines database, schema and schema-object privileges.
# object_privileges: object_type → list of privileges, or ["ALL"] for all_privileges.
#
# Built-in: R, RW
# Custom:   add any named profile here (e.g. REPORTING_READ, ADMIN_READ)
variable "privilege_profiles" {
  description = "Named privilege profiles reusable across databases"
  type = map(object({
    comment             = optional(string, "")
    database_privileges = optional(list(string), ["USAGE"])
    schema_privileges   = optional(list(string), ["USAGE"])
    object_privileges   = optional(map(list(string)), {})
  }))
  default = {}
}

# Per-database role configuration from database_roles.yaml.
# Each key is a database_key matching databases.yaml.
# Each role either references a privilege_profile by name (profile:)
# or defines privileges inline.
# role_name overrides the generated name completely (for custom roles).
#
# Generated name (when role_name is omitted):
#   DATABASE_ROLE_<DB>_<ENV>_<ROLE_KEY>
#
# Example:
#   databases:
#     gold:
#       roles:
#         R:  { profile: R }
#         RW: { profile: RW }
#         REPORTING_R:
#           role_name: "CUSTOM_DATABASE_ROLE_REPORTING_R"
#           profile: REPORTING_READ
variable "database_role_config" {
  description = "Per-database role definitions — profile reference or inline privileges"
  type = map(object({                              # key = database_key
    roles = map(object({                           # key = role_key (READ, READ_WRITE, ...)
      profile             = optional(string)       # reference to privilege_profiles key
      role_name           = optional(string)       # override generated name
      comment             = optional(string, "")
      allowed_schemas     = optional(list(string), []) # empty = all schemas (database-level grants)
      database_privileges = optional(list(string))
      schema_privileges   = optional(list(string))
      object_privileges   = optional(map(list(string)))
    }))
  }))
  default = {}
}

# Super-admin roles to grant each database role to. Defaults to SYSADMIN for all.
# Override per (db_key, role_key) pair:
#   { "bronze|R": ["SYSADMIN"], "gold|RW": ["SYSADMIN", "ACCOUNTADMIN"] }
variable "super_admin_roles" {
  description = "Map of '<db_key>|<role_key>' → list of account role names to receive each database role"
  type        = map(list(string))
  default     = {}
}
