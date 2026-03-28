// Technical account roles are generated from var.technical_roles.
// To add one (e.g., mlops):
// - Add an entry under var.technical_roles with optional parent_roles (defaults to ["SYSADMIN"]) and db_role_grants
// - Role will be created as TECHNICAL_ACCOUNT_ROLE_<KEY_UPPER>_<ENV> and granted to each parent in parent_roles
locals {
  technical_roles_expanded = {
    for key, cfg in var.technical_roles :
    key => {
      name = "TECHNICAL_ACCOUNT_ROLE_${upper(key)}_${var.snowflake_env}"
      # Omitted super_admin_roles => grant role to SYSADMIN. Explicit [] => no parent grants. Explicit list => those parents only.
      parent_roles = try(cfg.super_admin_roles, null) != null ? cfg.super_admin_roles : (
        length(coalesce(try(cfg.parent_roles, null), [])) > 0 ? coalesce(try(cfg.parent_roles, null), []) : [coalesce(try(cfg.parent_role, null), "SYSADMIN")]
      )
    }
  }

  technical_role_parent_bindings = {
    for m in flatten([
      for key, v in local.technical_roles_expanded : [
        for p in v.parent_roles : { role_key = key, parent = p }
      ]
    ]) : "${m.role_key}|${m.parent}" => m
  }
}

resource "snowflake_account_role" "technical_roles" {
  provider = snowflake.securityadmin
  for_each = local.technical_roles_expanded
  name     = each.value.name
}

resource "time_sleep" "technical_role_settle" {
  for_each        = local.technical_roles_expanded
  create_duration = "3s"
}

// Grants each technical role to its configured parent system role (default SYSADMIN).
resource "snowflake_grant_account_role" "role_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.technical_role_parent_bindings
  role_name        = snowflake_account_role.technical_roles[each.value.role_key].name
  parent_role_name = each.value.parent
  depends_on       = [time_sleep.technical_role_settle]
}
