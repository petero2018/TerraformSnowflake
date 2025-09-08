locals {
  technical_roles_expanded = {
    for key, cfg in var.technical_roles :
    key => {
      name        = "TECHNICAL_ROLE_${upper(key)}_${var.snowflake_env}"
      parent_role = cfg.parent_role
    }
  }
}

resource "snowflake_account_role" "technical_roles" {
  provider = snowflake.securityadmin
  for_each = local.technical_roles_expanded
  name     = each.value.name
}

resource "snowflake_grant_account_role" "role_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.technical_roles_expanded
  role_name        = snowflake_account_role.technical_roles[each.key].name
  parent_role_name = each.value.parent_role
}
