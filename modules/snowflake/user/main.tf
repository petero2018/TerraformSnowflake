locals {
  # Strip PEM headers/footers from public keys so Snowflake accepts them
  public_keys_normalized = {
    for key, pem in var.service_user_public_keys :
    key => trimspace(
      trimsuffix(
        trimprefix(chomp(pem), "-----BEGIN PUBLIC KEY-----"),
        "-----END PUBLIC KEY-----"
      )
    )
  }

  # Human user → business role grants flattened
  human_role_grants_flat = {
    for m in flatten([
      for username, role_keys in var.human_user_role_grants : [
        for role_key in role_keys : {
          id       = "${username}|${role_key}"
          username = username
          role_key = role_key
        }
      ]
    ]) : m.id => m
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Service users
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_user" "service_users" {
  provider = snowflake.useradmin
  for_each = var.service_users

  name         = "${each.value.name_prefix}_${var.snowflake_env}"
  display_name = each.value.display_name
  login_name   = each.value.login_name
  email        = each.value.email
  disabled     = each.value.disabled

  must_change_password = false
  disable_mfa          = true

  default_role                   = var.technical_roles[each.value.role].name
  default_secondary_roles_option = each.value.default_secondary_roles_option

  default_namespace = each.value.default_database != null ? var.databases[each.value.default_database].name : null
  default_warehouse = each.value.warehouse != null ? var.warehouses[each.value.warehouse].name : null

  rsa_public_key = try(local.public_keys_normalized[each.key], null)
}

# Grant the configured technical role to each service user
resource "snowflake_grant_account_role" "service_user_role" {
  provider = snowflake.securityadmin
  for_each = var.service_users

  role_name = var.technical_roles[each.value.role].name
  user_name = snowflake_user.service_users[each.key].name
}

# ──────────────────────────────────────────────────────────────────────────
# Human users — created by Terraform, auth managed by Okta SSO
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_user" "human_users" {
  provider = snowflake.useradmin
  for_each = var.managed_human_users

  name         = each.key
  display_name = each.value.display_name
  login_name   = each.value.login_name
  email        = each.value.email
  disabled     = each.value.disabled

  must_change_password = false # auth via Okta
  disable_mfa          = true  # MFA via Okta

  default_role                   = each.value.default_role
  default_secondary_roles_option = "ALL"
}

# Grant the configured business role to each managed human user
# Only grant if the role key actually exists in the provided business_roles map
# (handles the case where DEV or PROD roles haven't been provisioned yet)
resource "snowflake_grant_account_role" "human_user_business_role" {
  provider = snowflake.securityadmin
  for_each = {
    for k, u in var.managed_human_users : k => u
    if contains(keys(var.business_roles), u.role)
  }

  role_name  = var.business_roles[each.value.role].name
  user_name  = snowflake_user.human_users[each.key].name
  depends_on = [snowflake_user.human_users]
}

# ──────────────────────────────────────────────────────────────────────────
# Human user → business role grants (for pre-existing users not managed here)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_account_role" "human_user_role" {
  provider = snowflake.securityadmin
  for_each = {
    for k, m in local.human_role_grants_flat : k => m
    if contains(keys(var.business_roles), m.role_key)
  }

  role_name = var.business_roles[each.value.role_key].name
  user_name = each.value.username
}
