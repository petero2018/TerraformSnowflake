resource "snowflake_user" "users" {
  for_each = { for user in var.users : user.name => user }

  disabled = !each.value.enabled

  name         = each.key
  display_name = each.value.name
  login_name   = each.value.email
  email        = each.value.email

  must_change_password = false # Auth is managed by Okta
  disable_mfa          = true  # MFA is managed by Okta

  default_role                   = each.value.default_role
  default_secondary_roles_option = each.value.default_secondary_roles

  default_namespace = each.value.default_namespace
  default_warehouse = each.value.default_warehouse

  provider = snowflake.useradmin
}

locals {
  user_role_mappings = {
    for mapping in flatten([
      for user in var.users : [
        for role in concat([user.default_role], user.extra_roles) : { user : user.name, role : role }
      ]
    ]) : "${mapping.user}|${mapping.role}" => mapping
  }
}

resource "snowflake_grant_account_role" "extras" {
  for_each = local.user_role_mappings

  role_name = each.value.role
  user_name = snowflake_user.users[each.value.user].name

  provider = snowflake.securityadmin
}

# SYSTEM roles
resource "snowflake_grant_account_role" "useradmin" {
  for_each = toset([for user in var.users : user.name if user.system_role == "USERADMIN"])

  role_name = "USERADMIN"
  user_name = snowflake_user.users[each.value].name

  provider = snowflake.securityadmin
}

resource "snowflake_grant_account_role" "sysadmin" {
  for_each = toset([for user in var.users : user.name if user.system_role == "SYSADMIN"])

  role_name = "SYSADMIN"
  user_name = snowflake_user.users[each.value].name

  provider = snowflake.accountadmin
}

resource "snowflake_grant_account_role" "securityadmin" {
  for_each = toset([for user in var.users : user.name if user.system_role == "SECURITYADMIN"])

  role_name = "SECURITYADMIN"
  user_name = snowflake_user.users[each.value].name

  provider = snowflake.accountadmin
}

resource "snowflake_grant_account_role" "accountadmin" {
  for_each = toset([for user in var.users : user.name if user.system_role == "ACCOUNTADMIN"])

  role_name = "ACCOUNTADMIN"
  user_name = snowflake_user.users[each.value].name

  provider = snowflake.accountadmin
}

resource "snowflake_grant_account_role" "orgadmin" {
  for_each = toset([for user in var.users : user.name if user.is_orgadmin])

  role_name = "ORGADMIN"
  user_name = snowflake_user.users[each.value].name

  provider = snowflake.accountadmin
}
