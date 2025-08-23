
# BRONZE BASIC ROLES

resource "snowflake_database_role" "bronze_rw_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.bronze_db.fully_qualified_name
  name     = "ROLE_BRONZE_${var.snowflake_env}_RW"
}

resource "snowflake_database_role" "bronze_r_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.bronze_db.fully_qualified_name
  name     = "ROLE_BRONZE_${var.snowflake_env}_R"
}

# SILVER BASIC ROLES

resource "snowflake_database_role" "silver_rw_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.silver_db.fully_qualified_name
  name     = "ROLE_SILVER_${var.snowflake_env}_RW"
}

resource "snowflake_database_role" "silver_r_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.silver_db.fully_qualified_name
  name     = "ROLE_SILVER_${var.snowflake_env}_R"
}

# GOLD BASIC ROLES

resource "snowflake_database_role" "gold_rw_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.gold_db.fully_qualified_name
  name     = "ROLE_GOLD_${var.snowflake_env}_RW"
}

resource "snowflake_database_role" "gold_r_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.gold_db.fully_qualified_name
  name     = "ROLE_GOLD_${var.snowflake_env}_R"
}



# OPERATIONS BASIC ROLES

resource "snowflake_database_role" "operations_rw_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.operations_db.fully_qualified_name
  name     = "ROLE_OPERATIONS_${var.snowflake_env}_RW"
}

resource "snowflake_database_role" "operations_r_role" {
  provider = snowflake.sysadmin
  database = snowflake_database.operations_db.fully_qualified_name
  name     = "ROLE_OPERATIONS_${var.snowflake_env}_R"
}
