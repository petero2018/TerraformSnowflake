terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "2.14.1"
      configuration_aliases = [
        snowflake.useradmin,
        snowflake.securityadmin,
      ]
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}
