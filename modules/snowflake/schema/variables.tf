variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV, PROD, or empty string for env-agnostic schemas."
  default     = ""
  validation {
    condition     = contains(["DEV", "PROD", ""], var.snowflake_env)
    error_message = "snowflake_env must be DEV, PROD, or empty string."
  }
}

# Controls how the logical database key maps to the Snowflake database name.
# Mirrors the name_overrides in the database module so naming stays consistent.
# e.g. operations → OPERATION (singular, historical name)
variable "name_overrides" {
  description = "Map of logical database key → Snowflake name prefix override"
  type        = map(string)
  default = {
    operations = "OPERATION"
  }
}

# Valid database keys from databases.yaml — passed in from terragrunt so the
# module can validate that every schema references an existing database.
variable "valid_database_keys" {
  description = "List of valid logical database keys (keys of databases.yaml)"
  type        = list(string)
}

# schemas:
#   - database: bronze   ← must be a key in databases.yaml
#     name: MY_SCHEMA
#     comment: ""
#     is_transient: false
variable "schemas" {
  description = "List of schemas to create"
  type = list(object({
    database     = string
    name         = string
    comment      = optional(string, "")
    is_transient = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for s in var.schemas : contains(var.valid_database_keys, s.database)
    ])
    error_message = "One or more schemas reference a database key not found in databases.yaml. Invalid keys: ${join(", ", distinct([for s in var.schemas : s.database if !contains(var.valid_database_keys, s.database)]))}"
  }
}
