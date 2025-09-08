############################
# TRANSFORM ROLE
############################

resource "snowflake_account_role" "transform_technical_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_TRANSFORM_${var.snowflake_env}"
}

resource "snowflake_grant_account_role" "grant_transform_technical_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.transform_technical_role.name
  parent_role_name = "SYSADMIN"
}

############################
# INGESTION ROLE
############################

resource "snowflake_account_role" "ingestion_technical_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_INGESTION_${var.snowflake_env}"
}

resource "snowflake_grant_account_role" "grant_ingestion_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.ingestion_technical_role.name
  parent_role_name = "SYSADMIN"
}

############################
# REPORTING ROLE
############################

resource "snowflake_account_role" "reporting_technical_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_REPORTING_${var.snowflake_env}"
}

resource "snowflake_grant_account_role" "grant_reporting_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.reporting_technical_role.name
  parent_role_name = "SYSADMIN"
}

############################
# RETL ROLE
############################


resource "snowflake_account_role" "retl_technical_role" {
  provider = snowflake.securityadmin
  name     = "TECHNICAL_ROLE_RETL_${var.snowflake_env}"
}

resource "snowflake_grant_account_role" "grant_retl_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.retl_technical_role.name
  parent_role_name = "SYSADMIN"
}
