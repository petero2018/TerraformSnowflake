// Grants technical account roles to existing users by username.
// Configure via Terragrunt YAML under "tech_role_user_grants":
// tech_role_user_grants:
//   DBT_USER: ["transform"]
//   ANALYST_1: ["reporting"]

locals {
  tech_role_user_grants_flat = {
    for m in flatten([
      for user, roles in var.tech_role_user_grants : [
        for r in roles : {
          id       = "${user}|${r}"
          user     = user
          role_key = r
        }
      ]
    ]) : m.id => m
  }
}

resource "snowflake_grant_account_role" "tech_role_to_user" {
  provider = snowflake.securityadmin
  for_each = local.tech_role_user_grants_flat

  role_name = snowflake_account_role.technical_roles[each.value.role_key].name
  user_name = each.value.user
}

