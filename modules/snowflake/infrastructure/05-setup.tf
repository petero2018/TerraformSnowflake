terraform {
  required_version = ">= 1.7.0"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">=1"

      configuration_aliases = [
        snowflake.securityadmin,
        snowflake.sysadmin,
        snowflake.accountadmin,
        snowflake.useradmin,
      ]
    }
  }
}
