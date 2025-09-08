
############################
# TRANFROM ROLE GRANTS
############################

resource "snowflake_grant_database_role" "grant_operations_rw_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_rw_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_operations_r_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_bronze_rw_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_rw_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_bronze_r_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_silver_rw_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_rw_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_silver_r_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}


resource "snowflake_grant_database_role" "grant_gold_rw_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_rw_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}

resource "snowflake_grant_database_role" "grant_gold_r_to_transform_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.transform_technical_role.name
}


############################
# INGESTION ROLE GRANTS
############################

resource "snowflake_grant_database_role" "grant_bronze_rw_to_ingestion_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_rw_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.ingestion_technical_role.name
}

resource "snowflake_grant_database_role" "grant_bronze_r_to_ingestion_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.ingestion_technical_role.name
}



############################
# REPORTING ROLE GRANTS
############################

resource "snowflake_grant_database_role" "grant_gold_r_to_reporting_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.reporting_technical_role.name
}


############################
# RETL ROLE GRANTS
############################

resource "snowflake_grant_database_role" "grant_gold_r_to_retl_technical_role" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name
  parent_role_name   = snowflake_account_role.retl_technical_role.name
}
