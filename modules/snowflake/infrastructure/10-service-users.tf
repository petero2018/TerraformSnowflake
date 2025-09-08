// Service user keys: pass either public keys (preferred) or private keys to derive public.
data "tls_public_key" "service_users" {
  for_each = var.service_user_private_keys
  private_key_openssh = each.value
}

locals {
  // Normalize public keys: use provided public if exists, otherwise derive from private.
  service_user_public_keys_normalized = {
    for key in keys(merge(var.service_user_private_keys, var.service_user_public_keys)) :
    key => trimspace(
      trimsuffix(
        trimprefix(
          chomp(try(var.service_user_public_keys[key], data.tls_public_key.service_users[key].public_key_pem)),
          "-----BEGIN PUBLIC KEY-----"
        ),
        "-----END PUBLIC KEY-----"
      )
    )
  }

  service_users_expanded = {
    for key, cfg in var.service_users :
    key => {
      name              = "${cfg.name_prefix}_${var.snowflake_env}"
      default_role      = try(snowflake_account_role.technical_roles[cfg.default_role_key].name, cfg.default_role_key, null)
      default_wh_name   = try(snowflake_warehouse.warehouses[cfg.default_warehouse_key].name, null)
      default_db_name   = try(snowflake_database.databases[cfg.default_database_key].name, null)
      secondary_roles   = try(cfg.default_secondary_roles_option, "ALL")
      technical_roles   = try(cfg.technical_role_keys, [])
      display_name      = try(cfg.display_name, null)
      login_name        = try(cfg.login_name, null)
      email             = try(cfg.email, null)
      disabled          = try(cfg.disabled, false)
    }
  }

  // Flatten user -> role grants
  service_user_role_grants = {
    for m in flatten([
      for user_key, su in var.service_users : [
        for tr_key in try(su.technical_role_keys, []) : {
          id         = "${user_key}|${tr_key}"
          user_key   = user_key
          tr_key     = tr_key
        }
      ]
    ]) : m.id => m
  }
}

// Create service users
resource "snowflake_user" "service_users" {
  provider = snowflake.useradmin
  for_each = local.service_users_expanded

  disabled = each.value.disabled

  name         = each.value.name
  display_name = each.value.display_name
  login_name   = each.value.login_name
  email        = each.value.email

  must_change_password = false
  disable_mfa          = true

  default_role                   = each.value.default_role
  default_secondary_roles_option = each.value.secondary_roles

  default_namespace = each.value.default_db_name
  default_warehouse = each.value.default_wh_name

  rsa_public_key = try(local.service_user_public_keys_normalized[each.key], null)
}

// Grant technical roles to service users
resource "snowflake_grant_account_role" "service_user_role_grants" {
  provider = snowflake.securityadmin
  for_each = local.service_user_role_grants

  role_name = snowflake_account_role.technical_roles[each.value.tr_key].name
  user_name = snowflake_user.service_users[each.value.user_key].name
}
