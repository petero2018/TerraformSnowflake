// State migration hints to preserve resources across refactor
// Databases
moved {
  from = snowflake_database.bronze_db
  to   = snowflake_database.databases["bronze"]
}

moved {
  from = snowflake_database.silver_db
  to   = snowflake_database.databases["silver"]
}

moved {
  from = snowflake_database.gold_db
  to   = snowflake_database.databases["gold"]
}

moved {
  from = snowflake_database.operations_db
  to   = snowflake_database.databases["operations"]
}

moved {
  from = snowflake_database.retl_db
  to   = snowflake_database.databases["retl"]
}

// Database roles
moved {
  from = snowflake_database_role.bronze_r_role
  to   = snowflake_database_role.db_roles["bronze|R"]
}

moved {
  from = snowflake_database_role.bronze_rw_role
  to   = snowflake_database_role.db_roles["bronze|RW"]
}

moved {
  from = snowflake_database_role.silver_r_role
  to   = snowflake_database_role.db_roles["silver|R"]
}

moved {
  from = snowflake_database_role.silver_rw_role
  to   = snowflake_database_role.db_roles["silver|RW"]
}

moved {
  from = snowflake_database_role.gold_r_role
  to   = snowflake_database_role.db_roles["gold|R"]
}

moved {
  from = snowflake_database_role.gold_rw_role
  to   = snowflake_database_role.db_roles["gold|RW"]
}

moved {
  from = snowflake_database_role.operations_r_role
  to   = snowflake_database_role.db_roles["operations|R"]
}

moved {
  from = snowflake_database_role.operations_rw_role
  to   = snowflake_database_role.db_roles["operations|RW"]
}

// Warehouses
moved {
  from = snowflake_warehouse.transform_wh
  to   = snowflake_warehouse.warehouses["transform"]
}

moved {
  from = snowflake_warehouse.ingestion_wh
  to   = snowflake_warehouse.warehouses["ingestion"]
}

moved {
  from = snowflake_warehouse.reporting_wh
  to   = snowflake_warehouse.warehouses["reporting"]
}

moved {
  from = snowflake_warehouse.retl_wh
  to   = snowflake_warehouse.warehouses["retl"]
}

// Warehouse grants
moved {
  from = snowflake_grant_privileges_to_account_role.grant_warehouse_usage_to_transform_technical_role
  to   = snowflake_grant_privileges_to_account_role.warehouse_usage_monitors["transform|transform"]
}

moved {
  from = snowflake_grant_privileges_to_account_role.grant_warehouse_usage_to_ingestion_technical_role
  to   = snowflake_grant_privileges_to_account_role.warehouse_usage_monitors["ingestion|ingestion"]
}

moved {
  from = snowflake_grant_privileges_to_account_role.grant_warehouse_usage_to_reporting_technical_role
  to   = snowflake_grant_privileges_to_account_role.warehouse_usage_monitors["reporting|reporting"]
}

// Technical account roles
moved {
  from = snowflake_account_role.transform_technical_role
  to   = snowflake_account_role.technical_roles["transform"]
}

moved {
  from = snowflake_account_role.ingestion_technical_role
  to   = snowflake_account_role.technical_roles["ingestion"]
}

moved {
  from = snowflake_account_role.reporting_technical_role
  to   = snowflake_account_role.technical_roles["reporting"]
}

moved {
  from = snowflake_account_role.retl_technical_role
  to   = snowflake_account_role.technical_roles["retl"]
}

// Parent role grants
moved {
  from = snowflake_grant_account_role.grant_transform_technical_role_to_sysadmin
  to   = snowflake_grant_account_role.role_to_parent["transform"]
}

moved {
  from = snowflake_grant_account_role.grant_ingestion_role_to_sysadmin
  to   = snowflake_grant_account_role.role_to_parent["ingestion"]
}

moved {
  from = snowflake_grant_account_role.grant_reporting_role_to_sysadmin
  to   = snowflake_grant_account_role.role_to_parent["reporting"]
}

moved {
  from = snowflake_grant_account_role.grant_retl_role_to_sysadmin
  to   = snowflake_grant_account_role.role_to_parent["retl"]
}

// DB-role to technical-role grants
moved {
  from = snowflake_grant_database_role.grant_operations_rw_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|operations|RW"]
}

moved {
  from = snowflake_grant_database_role.grant_operations_r_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|operations|R"]
}

moved {
  from = snowflake_grant_database_role.grant_bronze_rw_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|bronze|RW"]
}

moved {
  from = snowflake_grant_database_role.grant_bronze_r_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|bronze|R"]
}

moved {
  from = snowflake_grant_database_role.grant_silver_rw_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|silver|RW"]
}

moved {
  from = snowflake_grant_database_role.grant_silver_r_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|silver|R"]
}

moved {
  from = snowflake_grant_database_role.grant_gold_rw_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|gold|RW"]
}

moved {
  from = snowflake_grant_database_role.grant_gold_r_to_transform_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["transform|gold|R"]
}

moved {
  from = snowflake_grant_database_role.grant_bronze_rw_to_ingestion_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["ingestion|bronze|RW"]
}

moved {
  from = snowflake_grant_database_role.grant_bronze_r_to_ingestion_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["ingestion|bronze|R"]
}

moved {
  from = snowflake_grant_database_role.grant_gold_r_to_reporting_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["reporting|gold|R"]
}

moved {
  from = snowflake_grant_database_role.grant_gold_r_to_retl_technical_role
  to   = snowflake_grant_database_role.db_role_to_tech["retl|gold|R"]
}

// Database-level grants (usage vs all)
moved {
  from = snowflake_grant_privileges_to_database_role.bronze_db_usage_to_bronze_r
  to   = snowflake_grant_privileges_to_database_role.db_grants_usage["bronze|R"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.bronze_db_all_privs_to_bronze_rw
  to   = snowflake_grant_privileges_to_database_role.db_grants_all["bronze|RW"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.silver_db_usage_to_silver_r
  to   = snowflake_grant_privileges_to_database_role.db_grants_usage["silver|R"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.silver_db_all_privs_to_silver_rw
  to   = snowflake_grant_privileges_to_database_role.db_grants_all["silver|RW"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.gold_db_usage_to_gold_r
  to   = snowflake_grant_privileges_to_database_role.db_grants_usage["gold|R"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.gold_db_all_privs_to_gold_rw
  to   = snowflake_grant_privileges_to_database_role.db_grants_all["gold|RW"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.operations_db_usage_to_operations_r
  to   = snowflake_grant_privileges_to_database_role.db_grants_usage["operations|R"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.operations_db_all_privs_to_operations_rw
  to   = snowflake_grant_privileges_to_database_role.db_grants_all["operations|RW"]
}

// Table grants (now=all scope)
moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_r_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["bronze|R|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_rw_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["bronze|RW|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_r_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["bronze|R|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_rw_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["bronze|RW|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_r_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["silver|R|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_rw_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["silver|RW|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_r_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["silver|R|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_rw_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["silver|RW|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_r_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["gold|R|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_rw_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["gold|RW|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_r_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["gold|R|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_rw_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["gold|RW|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_r_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["operations|R|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.table_grant_rw_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["operations|RW|TABLES|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_r_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["operations|R|TABLES|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_table_grant_rw_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["operations|RW|TABLES|future"]
}

// View grants (now=all scope)
moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_r_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["bronze|R|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_rw_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["bronze|RW|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_r_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["bronze|R|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_rw_to_bronze_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["bronze|RW|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_r_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["silver|R|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_rw_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["silver|RW|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_r_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["silver|R|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_rw_to_silver_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["silver|RW|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_r_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["gold|R|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_rw_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["gold|RW|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_r_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["gold|R|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_rw_to_gold_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["gold|RW|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_r_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["operations|R|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.view_grant_rw_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["operations|RW|VIEWS|all"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_r_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_select["operations|R|VIEWS|future"]
}

moved {
  from = snowflake_grant_privileges_to_database_role.future_view_grant_rw_to_operations_db
  to   = snowflake_grant_privileges_to_database_role.table_view_grants_all["operations|RW|VIEWS|future"]
}
