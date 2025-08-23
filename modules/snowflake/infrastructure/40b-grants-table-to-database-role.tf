############################
# VIEWS NOW — BRONZE
############################

resource "snowflake_grant_privileges_to_database_role" "view_grant_r_to_bronze_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.bronze_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "view_grant_rw_to_bronze_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.bronze_db.name
    }
  }
}

############################
# VIEWS FUTURE — BRONZE
############################

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_r_to_bronze_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.bronze_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_rw_to_bronze_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.bronze_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.bronze_db.name
    }
  }
}

############################
# VIEWS NOW — SILVER
############################

resource "snowflake_grant_privileges_to_database_role" "view_grant_r_to_silver_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.silver_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "view_grant_rw_to_silver_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.silver_db.name
    }
  }
}

############################
# VIEWS FUTURE — SILVER
############################

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_r_to_silver_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.silver_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_rw_to_silver_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.silver_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.silver_db.name
    }
  }
}

############################
# VIEWS NOW — GOLD
############################

resource "snowflake_grant_privileges_to_database_role" "view_grant_r_to_gold_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.gold_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "view_grant_rw_to_gold_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.gold_db.name
    }
  }
}

############################
# VIEWS FUTURE — GOLD
############################

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_r_to_gold_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.gold_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_rw_to_gold_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.gold_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.gold_db.name
    }
  }
}

############################
# VIEWS NOW — OPERATIONS
############################

resource "snowflake_grant_privileges_to_database_role" "view_grant_r_to_operations_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.operations_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "view_grant_rw_to_operations_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.operations_db.name
    }
  }
}

############################
# VIEWS FUTURE — OPERATIONS
############################

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_r_to_operations_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_r_role.fully_qualified_name

  privileges        = ["SELECT"]
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.operations_db.name
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "future_view_grant_rw_to_operations_db" {
  provider           = snowflake.securityadmin
  database_role_name = snowflake_database_role.operations_rw_role.fully_qualified_name

  all_privileges    = true
  with_grant_option = false

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.operations_db.name
    }
  }
}
