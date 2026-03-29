variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# databases:
#   bronze:
#     comment: "Raw ingestion layer"
#     data_retention_days: 1
#     transient: false
variable "databases" {
  description = "Map of logical database key → config"
  type = map(object({
    comment             = string
    data_retention_days = optional(number, 1)
    transient           = optional(bool, false)
  }))
}

# Controls how the logical key maps to the Snowflake database name.
# Default: upper(key)_ENV. Override specific keys here if historical names differ.
# e.g. operations → OPERATION (singular)
variable "name_overrides" {
  description = "Map of logical key → Snowflake name prefix override"
  type        = map(string)
  default = {
    operations = "OPERATION"
  }
}
