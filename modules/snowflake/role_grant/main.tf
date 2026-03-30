locals {
  # Flatten: technical role key × (db_key, role_key) pairs → grant tuples
  # database_access values are now direct role_key references (READ, READ_WRITE, REPORTING_R, ...)
  technical_grants = {
    for g in flatten([
      for role_key, db_access in var.technical_role_grants : [
        for db_key, db_role_key in db_access : {
          id           = "${role_key}|${db_key}|${upper(db_role_key)}"
          role_key     = role_key
          db_role_key  = "${db_key}|${upper(db_role_key)}"
        }
      ]
    ]) : g.id => g
  }

  # Flatten: business role key × (db_key, role_key) pairs → grant tuples
  business_grants = {
    for g in flatten([
      for role_key, db_access in var.business_role_grants : [
        for db_key, db_role_key in db_access : {
          id           = "${role_key}|${db_key}|${upper(db_role_key)}"
          role_key     = role_key
          db_role_key  = "${db_key}|${upper(db_role_key)}"
        }
      ]
    ]) : g.id => g
  }

  # Flatten: direct account role name × (db_key, role_key) pairs → grant tuples
  # Used for global stacks (no account role module output available)
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
  database_role_name = var.database_roles[each.value.db_role_key].fully_qualified_name
  parent_role_name   = var.technical_roles[each.value.role_key].name
}

resource "snowflake_grant_database_role" "to_business" {
  provider           = snowflake.securityadmin
  for_each           = local.business_grants
  database_role_name = var.database_roles[each.value.db_role_key].fully_qualified_name
  parent_role_name   = var.business_roles[each.value.role_key].name
}

# Direct grants — exact account role name (e.g. SYSADMIN), no account_role module output needed
resource "snowflake_grant_database_role" "direct" {
  provider           = snowflake.securityadmin
  for_each           = local.direct_grants
  database_role_name = var.database_roles[each.value.db_role_key].fully_qualified_name
  parent_role_name   = each.value.account_role
}
