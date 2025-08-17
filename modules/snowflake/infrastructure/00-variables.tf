variable "snowflake_env" {
  type        = string
  description = "The environment name for Snowflake, Allowed values: DEV, PROD, UAT"

  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "The snowflake_env variable must contain DEV, PROD, or UAT"
  }
}
