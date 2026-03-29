variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# warehouses:
#   transform:
#     size: SMALL
#     comment: "dbt workloads"
variable "warehouses" {
  description = "Map of logical warehouse key → config"
  type = map(object({
    size    = string
    comment = optional(string, "")
  }))
}
