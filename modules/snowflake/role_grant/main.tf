locals {
  # ── Computed Snowflake names from keys ──────────────────────────────────────
  # Mirrors the same logic used in the database_role and schema modules.

  db_names = {
    for db_key in var.valid_database_keys :
    db_key => var.snowflake_env == ""
      ? upper(lookup(var.name_overrides, db_key, db_key))
      : "${upper(lookup(var.name_overrides, db_key, db_key))}_${var.snowflake_env}"
  }

  # Compute fully_qualified_name for every db_key|ROLE_KEY combination.
  # Role name follows the same coalesce logic as database_role/locals.tf:
  #   role_name set    → use it as-is
  #   profile set      → DATABASE_ROLE_<DB>_<ENV?>_<PROFILE>
  #   else             → DATABASE_ROLE_<DB>_<ENV?>_<ROLE_KEY>
  # FQN format: "DB_NAME"."ROLE_NAME"  (Snowflake double-quote identifier format)
  db_role_fqns = {
    for entry in flatten([
      for db_key, db_cfg in var.db_role_config : [
        for role_key, role_cfg in db_cfg.roles : {
          map_key   = "${db_key}|${upper(role_key)}"
          db_key    = db_key
          role_name = coalesce(
            try(role_cfg.role_name, null),
            var.snowflake_env == ""
              ? "DATABASE_ROLE_${upper(db_key)}_${upper(replace(coalesce(try(role_cfg.profile, null), role_key), "-", "_"))}"
              : "DATABASE_ROLE_${upper(db_key)}_${var.snowflake_env}_${upper(replace(coalesce(try(role_cfg.profile, null), role_key), "-", "_"))}"
          )
        }
      ]
      if contains(var.valid_database_keys, db_key)
    ]) : entry.map_key => "\"${local.db_names[entry.db_key]}\".\"${entry.role_name}\""
  }

  # ── Grant flattening ────────────────────────────────────────────────────────

  # Flatten: technical role key × (db_key, role_key) pairs → grant tuples
  # database_access values are now direct role_key references (READ, READ_WRITE, REPORTING_R, ...)
  technical_grants = {
    for g in flatten([
      for role_key, db_access in var.technical_role_grants : [
        for db_key, db_role_key in db_access : {
          id          = "${role_key}|${db_key}|${upper(db_role_key)}"
          role_key    = role_key
          db_role_key = "${db_key}|${upper(db_role_key)}"
        }
      ]
    ]) : g.id => g
  }

  # Flatten: business role key × (db_key, role_key) pairs → grant tuples
  business_grants = {
    for g in flatten([
      for role_key, db_access in var.business_role_grants : [
        for db_key, db_role_key in db_access : {
          id          = "${role_key}|${db_key}|${upper(db_role_key)}"
          role_key    = role_key
          db_role_key = "${db_key}|${upper(db_role_key)}"
        }
      ]
    ]) : g.id => g
  }

  # Flatten: direct account role name × (db_key, role_key) pairs → grant tuples
  # Used for global stacks (e.g. SYSADMIN → account_admin: READ)
  direct_grants = {
    for g in flatten([
      for account_role, db_access in var.grants : [
        for db_key, db_role_key in db_access : {
          id           = "${account_role}|${db_key}|${upper(db_role_key)}"
          account_role = account_role
          db_role_key  = "${db_key}|${upper(db_role_key)}"
        }
      ]
    ]) : g.id => g
  }
}

resource "snowflake_grant_database_role" "to_technical" {
  provider           = snowflake.securityadmin
  for_each           = local.technical_grants
  database_role_name = local.db_role_fqns[each.value.db_role_key]
  parent_role_name   = "TECHNICAL_ACCOUNT_ROLE_${upper(each.value.role_key)}_${var.snowflake_env}"
}

resource "snowflake_grant_database_role" "to_business" {
  provider           = snowflake.securityadmin
  for_each           = local.business_grants
  database_role_name = local.db_role_fqns[each.value.db_role_key]
  parent_role_name   = "BUSINESS_ACCOUNT_ROLE_${upper(each.value.role_key)}_${var.snowflake_env}"
}

# Direct grants — exact account role name (e.g. SYSADMIN), no account_role module output needed
resource "snowflake_grant_database_role" "direct" {
  provider           = snowflake.securityadmin
  for_each           = local.direct_grants
  database_role_name = local.db_role_fqns[each.value.db_role_key]
  parent_role_name   = each.value.account_role
}
