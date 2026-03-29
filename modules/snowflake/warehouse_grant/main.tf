locals {
  technical_grants_flat = {
    for g in flatten([
      for wh_key, role_keys in var.technical_warehouse_grants : [
        for role_key in role_keys : {
          id       = "${wh_key}|${role_key}"
          wh_key   = wh_key
          role_key = role_key
        }
      ]
    ]) : g.id => g
  }

  business_grants_flat = {
    for g in flatten([
      for wh_key, role_keys in var.business_warehouse_grants : [
        for role_key in role_keys : {
          id       = "${wh_key}|${role_key}"
          wh_key   = wh_key
          role_key = role_key
        }
      ]
    ]) : g.id => g
  }
}

# Technical roles: USAGE + MONITOR
resource "snowflake_grant_privileges_to_account_role" "technical" {
  provider          = snowflake.securityadmin
  for_each          = local.technical_grants_flat
  account_role_name = var.technical_roles[each.value.role_key].name
  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouses[each.value.wh_key].name
  }
}

# Business roles: USAGE + MONITOR + OPERATE (humans can suspend/resume)
resource "snowflake_grant_privileges_to_account_role" "business" {
  provider          = snowflake.securityadmin
  for_each          = local.business_grants_flat
  account_role_name = var.business_roles[each.value.role_key].name
  privileges        = ["USAGE", "MONITOR", "OPERATE"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouses[each.value.wh_key].name
  }
}
