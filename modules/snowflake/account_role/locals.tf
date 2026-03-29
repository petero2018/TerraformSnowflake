locals {
  technical_roles_expanded = {
    for key, cfg in var.technical_roles :
    key => {
      name         = "TECHNICAL_ACCOUNT_ROLE_${upper(key)}_${var.snowflake_env}"
      comment      = cfg.comment
      parent_roles = cfg.super_admin_roles != null ? cfg.super_admin_roles : ["SYSADMIN"]
    }
  }

  business_roles_expanded = {
    for key, cfg in var.business_roles :
    key => {
      name         = "BUSINESS_ACCOUNT_ROLE_${upper(key)}_${var.snowflake_env}"
      comment      = cfg.comment
      parent_roles = cfg.super_admin_roles != null ? cfg.super_admin_roles : ["SYSADMIN"]
    }
  }

  technical_parent_bindings = {
    for m in flatten([
      for key, v in local.technical_roles_expanded : [
        for p in v.parent_roles : { role_key = key, parent = p }
      ]
    ]) : "${m.role_key}|${m.parent}" => m
  }

  business_parent_bindings = {
    for m in flatten([
      for key, v in local.business_roles_expanded : [
        for p in v.parent_roles : { role_key = key, parent = p }
      ]
    ]) : "${m.role_key}|${m.parent}" => m
  }
}
