variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# Grant maps from warehouses.yaml — no cross-stack output dependency needed.
# warehouse_key and role_key are resolved to Snowflake names directly in the module.
variable "technical_warehouse_grants" {
  description = "Map of warehouse key → list of technical role keys to grant USAGE+MONITOR"
  type        = map(list(string))
  default     = {}
}

variable "business_warehouse_grants" {
  description = "Map of warehouse key → list of business role keys to grant USAGE+MONITOR+OPERATE"
  type        = map(list(string))
  default     = {}
}
