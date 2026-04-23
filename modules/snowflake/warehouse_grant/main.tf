locals {
  technical_grants_flat = {
    for g in flatten([
      for wh_key, role_keys in var.technical_warehouse_grants : [
        for role_key in role_keys : {
          id            = "${wh_key}|${role_key}"
          wh_name       = "${upper(wh_key)}_${var.snowflake_env}"
          role_name     = "TECHNICAL_ACCOUNT_ROLE_${upper(role_key)}_${var.snowflake_env}"
        }
      ]
    ]) : g.id => g
  }

  business_grants_flat = {
    for g in flatten([
      for wh_key, role_keys in var.business_warehouse_grants : [
        for role_key in role_keys : {
          id            = "${wh_key}|${role_key}"
          wh_name       = "${upper(wh_key)}_${var.snowflake_env}"
          role_name     = "BUSINESS_ACCOUNT_ROLE_${upper(role_key)}_${var.snowflake_env}"
        }
      ]
    ]) : g.id => g
  }
}

# Technical roles: USAGE + MONITOR
resource "snowflake_grant_privileges_to_account_role" "technical" {
  provider          = snowflake.securityadmin
  for_each          = local.technical_grants_flat
  account_role_name = each.value.role_name
  privileges        = ["USAGE", "MONITOR"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = each.value.wh_name
  }
}

# Business roles: USAGE + MONITOR + OPERATE (humans can suspend/resume)
resource "snowflake_grant_privileges_to_account_role" "business" {
  provider          = snowflake.securityadmin
  for_each          = local.business_grants_flat
  account_role_name = each.value.role_name
  privileges        = ["USAGE", "MONITOR", "OPERATE"]
  with_grant_option = false

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = each.value.wh_name
  }
}
