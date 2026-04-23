locals {
  # Compute Snowflake database names from keys — same logic as the database module.
  db_names = {
    for db_key in var.valid_database_keys :
    db_key => "${upper(lookup(var.name_overrides, db_key, db_key))}_${var.snowflake_env}"
  }

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

  # Expand each managed human user × each grant_env into individual grant entries.
  _human_business_grant_entries = flatten([
    for user_key, u in var.managed_human_users : [
      for env in try(u.grant_envs, []) : {
        id        = "${user_key}|${env}"
        user_key  = user_key
        env       = upper(env)
        role_key  = u.role
        role_name = "BUSINESS_ACCOUNT_ROLE_${upper(u.role)}_${upper(env)}"
      }
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

  default_role                   = "TECHNICAL_ACCOUNT_ROLE_${upper(each.value.role)}_${var.snowflake_env}"
  default_secondary_roles_option = "ALL"

  default_namespace = each.value.default_database != null ? local.db_names[each.value.default_database] : null
  default_warehouse = each.value.warehouse != null ? "${upper(each.value.warehouse)}_${var.snowflake_env}" : null

  # query_tag: svc_<name_prefix> (lowercased for readability)
  query_tag = "svc_${lower(each.value.name_prefix)}"

  rsa_public_key = try(local.public_keys_normalized[each.key], null)

  # Attach env-specific network policy when a key is provided.
  # Pattern mirrors 09-svc-user-network-policies: "${key}_${lower(env)}" → uppercased.
  # e.g. key="svc_users", env="DEV" → "SVC_USERS_DEV"
  network_policy = each.value.network_policy_key != null ? upper("${each.value.network_policy_key}_${var.snowflake_env}") : null
}

# Grant the configured technical role to each service user
resource "snowflake_grant_account_role" "service_user_role" {
  provider = snowflake.securityadmin
  for_each = var.service_users

  role_name = "TECHNICAL_ACCOUNT_ROLE_${upper(each.value.role)}_${var.snowflake_env}"
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
# Role name is computed: BUSINESS_ACCOUNT_ROLE_<ROLE_KEY>_<ENV>
resource "snowflake_grant_account_role" "human_user_business_role" {
  provider = snowflake.securityadmin
  for_each = local.human_business_grants

  role_name  = each.value.role_name
  user_name  = snowflake_user.human_users[each.value.user_key].name
  depends_on = [snowflake_user.human_users]
}

# ──────────────────────────────────────────────────────────────────────────
# Human user → business role grants (for pre-existing users not managed here)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_account_role" "human_user_role" {
  provider = snowflake.securityadmin
  for_each = local.human_role_grants_flat

  # Compute role name from key — no output dependency needed.
  # human_user_role_grants maps username -> [role_key, ...]; env is not specified,
  # so we always use the prod env suffix (account-level grants are env-agnostic).
  role_name = "BUSINESS_ACCOUNT_ROLE_${upper(each.value.role_key)}_PROD"
  user_name = each.value.username
}
