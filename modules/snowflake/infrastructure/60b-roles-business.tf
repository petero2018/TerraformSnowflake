// Business account roles are generated from var.business_roles.
// Role name pattern: BUSINESS_ACCOUNT_ROLE_<KEY_UPPER>_<ENV>
locals {
  business_roles_expanded = {
    for key, cfg in var.business_roles :
    key => {
      name        = "BUSINESS_ACCOUNT_ROLE_${upper(key)}_${var.snowflake_env}"
      parent_roles = length(coalesce(try(cfg.super_admin_roles, null), [])) > 0 ? coalesce(try(cfg.super_admin_roles, null), []) : (length(coalesce(try(cfg.parent_roles, null), [])) > 0 ? coalesce(try(cfg.parent_roles, null), []) : [ coalesce(try(cfg.parent_role, null), "SYSADMIN") ])
    }
  }

  business_role_parent_bindings = {
    for m in flatten([
      for key, v in local.business_roles_expanded : [
        for p in v.parent_roles : { role_key = key, parent = p }
      ]
    ]) : "${m.role_key}|${m.parent}" => m
  }
}

resource "snowflake_account_role" "business_roles" {
  provider = snowflake.securityadmin
  for_each = local.business_roles_expanded
  name     = each.value.name
}

resource "time_sleep" "business_role_settle" {
  for_each        = local.business_roles_expanded
  create_duration = "3s"
}

// Grant each business role to its configured parent system role
resource "snowflake_grant_account_role" "business_role_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.business_role_parent_bindings
  role_name        = snowflake_account_role.business_roles[each.value.role_key].name
  parent_role_name = each.value.parent
  depends_on       = [time_sleep.business_role_settle]
}
