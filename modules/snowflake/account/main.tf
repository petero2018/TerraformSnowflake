resource "snowflake_account" "accounts" {
  # Requires ORGADMIN role — use the snowflake.orgadmin provider alias.
  provider = snowflake.orgadmin
  for_each = var.accounts

  name    = each.value.name
  edition = each.value.edition
  region  = each.value.region
  comment = each.value.comment

  # Initial admin user — bootstraps access to the new account.
  # Use RSA key auth when available (more secure than password).
  admin_name           = each.value.admin_name
  admin_rsa_public_key = each.value.admin_rsa_public_key
  admin_user_type      = each.value.admin_user_type
  admin_password       = each.value.admin_rsa_public_key == null ? each.value.admin_password : null
  email                = each.value.email
  must_change_password = each.value.admin_rsa_public_key != null ? false : each.value.must_change_password
  grace_period_in_days = each.value.grace_period_in_days
  is_org_admin         = each.value.is_org_admin

}
