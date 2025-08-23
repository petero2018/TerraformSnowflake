variable "snowflake_env" {
  type        = string
  description = "ENV in caps. Allowed: DEV, PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}
