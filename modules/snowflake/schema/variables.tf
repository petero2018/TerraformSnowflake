variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV, PROD, or empty string for env-agnostic schemas."
  default     = ""
  validation {
    condition     = contains(["DEV", "PROD", ""], var.snowflake_env)
    error_message = "snowflake_env must be DEV, PROD, or empty string."
  }
}

# databases input: output of the database module
# { bronze: { name: "BRONZE_DEV", fully_qualified_name: "..." }, ... }
variable "databases" {
  description = "Map of logical database key → database attributes (output from database module)"
  type = map(object({
    name                = string
    fully_qualified_name = string
  }))
}

# schemas:
#   - database: bronze
#     name: SAMPLE_BRONZE_SCHEMA_ONE
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
}
