// Central derivations and grant matrices.
// Extend here when introducing new database layers, warehouses, or object types.
locals {
  env_upper = var.snowflake_env
  env_lower = lower(var.snowflake_env)

  // Terragrunt is expected to read YAML and pass maps to these variables as inputs.
  input_technical_roles   = var.technical_roles
  input_business_roles    = var.business_roles
  input_schema_privileges = var.schema_privileges
  input_database_roles    = var.database_roles
  input_databases         = var.databases
  input_warehouses        = var.warehouses

  # Databases keyed by logical layer (bronze/silver/gold/operations/retl)
  # To add a new database key (e.g. platinum):
  # - Add "platinum" to var.databases (00-variables.tf or Terragrunt inputs)
  # - Add an entry below to control its Snowflake name prefix
  # Preserve historical naming (OPERATION is singular for database)
  db_name_prefix = {
    bronze     = "BRONZE"
    silver     = "SILVER"
    gold       = "GOLD"
    operations = "OPERATION"  # singular in original resources
    retl       = "RETL"
  }
  dbs = {
    for key, cfg in local.input_databases :
    key => {
      key     = key,
      name    = "${lookup(local.db_name_prefix, key, upper(key))}_${var.snowflake_env}"
      comment = cfg.comment
    }
  }

  # Determine all (db, kind) pairs to materialize roles for:
  # - Explicit list via var.database_roles (preferred)
  # - Any pair referenced by tech/business grants or schema_privileges
  db_kind_pairs = distinct(concat(
    [ for dr in local.input_database_roles : "${dr.db}|${upper(dr.kind)}" ],
    flatten([ for _, tr in local.input_technical_roles : [ for g in try(tr.db_role_grants, []) : "${g.db}|${upper(g.kind)}" ] ]),
    flatten([ for _, br in local.input_business_roles  : [ for g in try(br.db_role_grants, []) : "${g.db}|${upper(g.kind)}" ] ]),
    [ for sp in local.input_schema_privileges : "${sp.db}|${upper(sp.kind)}" ]
  ))

  # Flattened role matrix for database roles and grants, used by downstream resources
  role_matrix = {
    for pair in local.db_kind_pairs :
    pair => {
      db_key    = element(split("|", pair), 0)
      role_kind = element(split("|", pair), 1)
      role_name = "DATABASE_ROLE_${upper(element(split("|", pair), 0))}_${var.snowflake_env}_${element(split("|", pair), 1)}"
      all_privs = element(split("|", pair), 1) == "RW"
    }
  }

  # Which schema object types and scopes we manage grants for.
  # Controlled via var.object_types_for_grants, e.g. ["TABLES", "VIEWS", "DYNAMIC TABLES", "STAGES", "FILE FORMATS", "MATERIALIZED VIEWS"].
  object_types = var.object_types_for_grants
  scopes       = ["all", "future"]

  # Per-object read privileges for R roles (RW uses all_privs=true)
  # Default to SELECT for most objects; override where Snowflake requires other privileges
  object_read_privileges = {
    "STAGES"             = ["USAGE"]
    "FILE FORMATS"       = ["USAGE"]
    "FUNCTIONS"          = ["USAGE"]
    "PIPES"              = ["MONITOR"]
    "EXTERNAL TABLES"    = ["SELECT"]
    "MATERIALIZED VIEWS" = ["SELECT"]
    "ICEBERG TABLES"     = ["SELECT"]
  }

  # Table/View grant combinations (all + future) per db role
  # - For R roles we set privileges = ["SELECT"], for RW we set all_privileges = true
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
            privileges = rm.all_privs ? null : lookup(local.object_read_privileges, obj, ["SELECT"])
            all_privs  = rm.all_privs
          }
        ]
      ]
    ]) : combo.id => combo
  }

  # Map technical-role keys to actual Snowflake account role names (from for_each resource)
  # - Keeps warehouse grant logic decoupled from role naming
  technical_roles = {
    for k, r in snowflake_account_role.technical_roles : k => r.name
  }
  business_roles = {
    for k, r in snowflake_account_role.business_roles : k => r.name
  }

  # Unified warehouse grants from explicit YAML list
  input_warehouse_grants = var.warehouse_grants
  warehouse_grants_unified = {
    for g in flatten([
      for item in local.input_warehouse_grants : [
        for rk in item.role_keys : {
          id        = "${item.warehouse}|${item.role_type}|${rk}"
          wh_key    = item.warehouse
          role_type = lower(item.role_type)
          role_key  = rk
        }
      ]
    ]) : g.id => g
  }

  # Warehouses keyed by logical key (transform/ingestion/reporting/retl/browse/etc.)
  # - Define warehouses under var.warehouses (00-variables.tf or Terragrunt inputs)
  whs = {
    for key, cfg in local.input_warehouses :
    key => merge(cfg, {
      key  = key,
      name = "${upper(key)}_WH_${var.snowflake_env}"
    })
  }

  # Flattened warehouse grants from unified YAML list
  warehouse_grants = {
    for _, v in local.warehouse_grants_unified :
    "${v.wh_key}|${v.role_key}" => {
      wh_key  = v.wh_key
      grantee = v.role_key
    } if v.role_type == "technical"
  }

  warehouse_grants_business = {
    for _, v in local.warehouse_grants_unified :
    "${v.wh_key}|${v.role_key}|business" => {
      wh_key  = v.wh_key
      grantee = v.role_key
    } if v.role_type == "business"
  }

  # Flatten technical db-role grants: join technical_roles with local.role_matrix
  # - Derived from var.technical_roles[*].db_role_grants (db, kind)
  # - db must match var.databases key; kind is "R" or "RW"
  technical_db_role_grants = {
    for g in flatten([
      for tr_key, tr in local.input_technical_roles : [
        for grant in tr.db_role_grants : {
          id       = "${tr_key}|${grant.db}|${upper(grant.kind)}"
          tr_key   = tr_key
          role_key = "${grant.db}|${upper(grant.kind)}"
        }
      ]
    ]) : g.id => g
  }
}
