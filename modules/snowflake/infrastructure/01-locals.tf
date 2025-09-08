locals {
  env_upper = var.snowflake_env
  env_lower = lower(var.snowflake_env)

  # Databases keyed by logical layer (bronze/silver/gold/operations/retl)
  # Preserve historical naming (OPERATION is singular for database)
  db_name_prefix = {
    bronze     = "BRONZE"
    silver     = "SILVER"
    gold       = "GOLD"
    operations = "OPERATION"  # singular in original resources
    retl       = "RETL"
  }
  dbs = {
    for key, cfg in var.databases :
    key => merge(cfg, {
      key     = key,
      name    = "${local.db_name_prefix[key]}_${var.snowflake_env}",
      r_role  = "ROLE_${upper(key)}_${var.snowflake_env}_R",
      rw_role = "ROLE_${upper(key)}_${var.snowflake_env}_RW"
    })
  }

  # Flattened role matrix for database roles and grants
  role_matrix = {
    for r in flatten([
      for key, v in local.dbs : [
        for kind in v.roles : {
          id        = "${key}|${kind}"
          db_key    = key
          role_kind = kind            # "R" or "RW"
          role_name = kind == "R" ? v.r_role : v.rw_role
          all_privs = kind == "RW"   # used for DB/table/view grants
        }
      ]
    ]) : r.id => r
  }

  object_types = ["TABLES", "VIEWS"]
  scopes       = ["all", "future"]

  # Table/View grant combinations (all + future) per db role
  table_view_grants = {
    for combo in flatten([
      for rm_key, rm in local.role_matrix : [
        for obj in local.object_types : [
          for sc in local.scopes : {
            id        = "${rm.db_key}|${rm.role_kind}|${obj}|${sc}"
            db_key    = rm.db_key
            role_id   = rm_key
            role_kind = rm.role_kind
            object    = obj      # "TABLES" or "VIEWS"
            scope     = sc       # "all" or "future"
            privileges = rm.all_privs ? null : ["SELECT"]
            all_privs  = rm.all_privs
          }
        ]
      ]
    ]) : combo.id => combo
  }

  # Map technical-role keys to actual Snowflake account role names (from for_each resource)
  technical_roles = {
    for k, r in snowflake_account_role.technical_roles : k => r.name
  }

  # Warehouses keyed by logical key (transform/ingestion/reporting/retl)
  whs = {
    for key, cfg in var.warehouses :
    key => merge(cfg, {
      key  = key,
      name = "${upper(key)}_WH_${var.snowflake_env}"
    })
  }

  # Flattened warehouse grant matrix: each grantee gets USAGE+MONITOR on the warehouse
  warehouse_grants = {
    for g in flatten([
      for key, wh in local.whs : [
        for gr in wh.grantees : {
          id       = "${key}|${gr}"
          wh_key   = key
          grantee  = gr
        }
      ]
    ]) : g.id => g
  }

  # Flatten technical db-role grants: join technical_roles with local.role_matrix
  technical_db_role_grants = {
    for g in flatten([
      for tr_key, tr in var.technical_roles : [
        for grant in tr.db_role_grants : {
          id       = "${tr_key}|${grant.db}|${upper(grant.kind)}"
          tr_key   = tr_key
          role_key = "${grant.db}|${upper(grant.kind)}"
        }
      ]
    ]) : g.id => g
  }
}
