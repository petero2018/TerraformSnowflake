terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "2.14.1"
      configuration_aliases = [snowflake.orgadmin]
    }
  }
  required_version = ">= 1.5"
}
