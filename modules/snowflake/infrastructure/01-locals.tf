locals {
  env_upper = var.snowflake_env
  env_lower = lower(var.snowflake_env)
}
