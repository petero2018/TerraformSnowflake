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

  # Per-env business role map — used for managed human user grants
  _business_roles_by_env = {
    dev  = var.business_roles_dev
    prod = var.business_roles_prod
  }

  # Expand each managed human user × each grant_env into individual grant entries.
  # Only include entries where the role key actually exists in that env's output
  # (guards against applying before the env stack has been applied).
  _human_business_grant_entries = flatten([
    for user_key, u in var.managed_human_users : [
      for env in try(u.grant_envs, []) : {
        id       = "${user_key}|${env}"
        user_key = user_key
        env      = env
        role_key = u.role
      }
      if contains(keys(try(local._business_roles_by_env[env], {})), u.role)
    ]
  ])

  human_business_grants = {
    for e in local._human_business_grant_entries : e.id => e
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Service users
# ──────────────────────────────────────────────────────────────────────────

resource "snowflake_service_user" "service_users" {
  provider = snowflake.useradmin
  for_each = var.service_users

  name         = "${each.value.name_prefix}_${var.snowflake_env}"
  display_name = each.value.display_name
  login_name   = each.value.login_name
  email        = each.value.email
  disabled     = each.value.disabled

  default_role                   = var.technical_roles[each.value.role].name
  default_secondary_roles_option = "ALL"

  default_namespace = each.value.default_database != null ? var.databases[each.value.default_database].name : null
  default_warehouse = each.value.warehouse != null ? var.warehouses[each.value.warehouse].name : null

  # query_tag: svc_<name_prefix> (lowercased for readability)
  query_tag = "svc_${lower(each.value.name_prefix)}"

  rsa_public_key = try(local.public_keys_normalized[each.key], null)

  # Attach env-specific network policy when provided.
  # The policy name is the resolved Snowflake name (e.g. "SVC_USERS") passed
  # in from the 08-service-users terragrunt inputs — not a module-local key.
  network_policy = each.value.network_policy
}

# Grant the configured technical role to each service user
resource "snowflake_grant_account_role" "service_user_role" {
  provider = snowflake.securityadmin
  for_each = var.service_users

  role_name = var.technical_roles[each.value.role].name
  user_name = snowflake_service_user.service_users[each.key].name
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

  query_tag =  each.value.query_tag
}

# Grant the configured business role to each managed human user × each grant_env.
# Key format: "<user_key>|<env>" e.g. "BUSINESS_USER_DATA_ENGINEER|dev"
# Only entries where the role key exists in that env's output are included (see locals).
resource "snowflake_grant_account_role" "human_user_business_role" {
  provider = snowflake.securityadmin
  for_each = local.human_business_grants

  role_name  = local._business_roles_by_env[each.value.env][each.value.role_key].name
  user_name  = snowflake_user.human_users[each.value.user_key].name
  depends_on = [snowflake_user.human_users]
}

# ──────────────────────────────────────────────────────────────────────────
# Human user → business role grants (for pre-existing users not managed here)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_account_role" "human_user_role" {
  provider = snowflake.securityadmin
  for_each = {
    for k, m in local.human_role_grants_flat : k => m
    if contains(keys(var.business_roles_dev), m.role_key) || contains(keys(var.business_roles_prod), m.role_key)
  }

  role_name = try(
    var.business_roles_prod[each.value.role_key].name,
    var.business_roles_dev[each.value.role_key].name
  )
  user_name = each.value.username
}
