// Grants business account roles to existing users by username.
// Configure via Terragrunt YAML under "business_role_user_grants":
// business_role_user_grants:
//   BUSINESS_USER_ANALYTICS_ENGINEER: ["analytics_engineer"]
//   BUSINESS_USER_ANALYST: ["analyst"]

locals {
  business_role_user_grants_flat = {
    for m in flatten([
      for user, roles in var.business_role_user_grants : [
        for r in roles : {
          id       = "${user}|${r}"
          user     = user
          role_key = r
        }
      ]
    ]) : m.id => m
  }
}

resource "snowflake_grant_account_role" "business_role_to_user" {
  provider = snowflake.securityadmin
  for_each = local.business_role_user_grants_flat

  role_name = snowflake_account_role.business_roles[each.value.role_key].name
  user_name = each.value.user
}

