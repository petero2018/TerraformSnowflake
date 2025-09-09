// Business account roles are generated from var.business_roles.
// Role name pattern: BUSINESS_ACCOUNT_ROLE_<KEY_UPPER>_<ENV>
locals {
  business_roles_expanded = {
    for key, cfg in var.business_roles :
    key => {
      name        = "BUSINESS_ACCOUNT_ROLE_${upper(key)}_${var.snowflake_env}"
      parent_role = cfg.parent_role
    }
  }
}

resource "snowflake_account_role" "business_roles" {
  provider = snowflake.securityadmin
  for_each = local.business_roles_expanded
  name     = each.value.name
}

// Grant each business role to its configured parent system role
resource "snowflake_grant_account_role" "business_role_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.business_roles_expanded
  role_name        = snowflake_account_role.business_roles[each.key].name
  parent_role_name = each.value.parent_role
}
