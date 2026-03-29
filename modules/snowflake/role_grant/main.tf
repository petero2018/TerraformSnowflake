locals {
  # Flatten: technical role key × (db, kind) pairs → grant tuples
  technical_grants = {
    for g in flatten([
      for role_key, db_access in var.technical_role_grants : [
        for db_key, kind in db_access : {
          id        = "${role_key}|${db_key}|${upper(kind)}"
          role_key  = role_key
          db_role_key = "${db_key}|${upper(kind)}"
        }
      ]
    ]) : g.id => g
  }

  # Flatten: business role key × (db, kind) pairs → grant tuples
  business_grants = {
    for g in flatten([
      for role_key, db_access in var.business_role_grants : [
        for db_key, kind in db_access : {
          id          = "${role_key}|${db_key}|${upper(kind)}"
          role_key    = role_key
          db_role_key = "${db_key}|${upper(kind)}"
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
