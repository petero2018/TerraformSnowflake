# ---------------------
# BRONZE (DB ROLE GRANTS)
# ---------------------

resource "snowflake_grant_privileges_to_database_role" "bronze_db_usage_to_bronze_r" {
  provider           = snowflake.securityadmin
  privileges         = ["USAGE"]
  database_role_name = snowflake_database_role.bronze_r_role.fully_qualified_name
  on_database        = snowflake_database.bronze_db.name
  with_grant_option  = false
}

resource "snowflake_grant_privileges_to_database_role" "bronze_db_all_privs_to_bronze_rw" {
  provider           = snowflake.securityadmin
  all_privileges     = true
  database_role_name = snowflake_database_role.bronze_rw_role.fully_qualified_name
  on_database        = snowflake_database.bronze_db.name
  with_grant_option  = false
}

# ---------------------
# SILVER (DB ROLE GRANTS)
# ---------------------

resource "snowflake_grant_privileges_to_database_role" "silver_db_usage_to_silver_r" {
  provider           = snowflake.securityadmin
  privileges         = ["USAGE"]
  database_role_name = snowflake_database_role.silver_r_role.fully_qualified_name
  on_database        = snowflake_database.silver_db.name
  with_grant_option  = false
}

resource "snowflake_grant_privileges_to_database_role" "silver_db_all_privs_to_silver_rw" {
  provider           = snowflake.securityadmin
  all_privileges     = true
  database_role_name = snowflake_database_role.silver_rw_role.fully_qualified_name
  on_database        = snowflake_database.silver_db.name
  with_grant_option  = false
}

# ---------------------
# GOLD (DB ROLE GRANTS)
# ---------------------

resource "snowflake_grant_privileges_to_database_role" "gold_db_usage_to_gold_r" {
  provider           = snowflake.securityadmin
  privileges         = ["USAGE"]
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name
  on_database        = snowflake_database.gold_db.name
  with_grant_option  = false
}

resource "snowflake_grant_privileges_to_database_role" "gold_db_all_privs_to_gold_rw" {
  provider           = snowflake.securityadmin
  all_privileges     = true
  database_role_name = snowflake_database_role.gold_rw_role.fully_qualified_name
  on_database        = snowflake_database.gold_db.name
  with_grant_option  = false
}

# ---------------------
# OPERATIONS (DB ROLE GRANTS)
# ---------------------

resource "snowflake_grant_privileges_to_database_role" "operations_db_usage_to_operations_r" {
  provider           = snowflake.securityadmin
  privileges         = ["USAGE"]
  database_role_name = snowflake_database_role.operations_r_role.fully_qualified_name
  on_database        = snowflake_database.operations_db.name
  with_grant_option  = false
}

resource "snowflake_grant_privileges_to_database_role" "operations_db_all_privs_to_operations_rw" {
  provider           = snowflake.securityadmin
  all_privileges     = true
  database_role_name = snowflake_database_role.operations_rw_role.fully_qualified_name
  on_database        = snowflake_database.operations_db.name
  with_grant_option  = false
}
