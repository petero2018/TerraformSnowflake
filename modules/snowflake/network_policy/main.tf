# ──────────────────────────────────────────────────────────────────────────────
# 1. Network rules
# ──────────────────────────────────────────────────────────────────────────────
# Schema-scoped objects: database.schema.name
# The target schema (ACCOUNT_ADMIN.NETWORK_POLICY) is created by the
# account/admin-schemas stack and must exist before this module is applied.
#
# type:  IPV4 (most common for ingress IP allow/block)
# mode:  INGRESS (restrict who can connect to Snowflake)
#        EGRESS  (restrict where Snowflake can connect out)

resource "snowflake_network_rule" "rules" {
  provider = snowflake.sysadmin
  for_each = var.network_rules

  database   = var.security_database
  schema     = var.security_schema
  name       = upper(each.key)
  type       = each.value.type
  mode       = each.value.mode
  value_list = toset(each.value.value_list)
  comment    = each.value.comment
}

# ──────────────────────────────────────────────────────────────────────────────
# 3. Network policies
# ──────────────────────────────────────────────────────────────────────────────
# Account-level objects that reference network rules by fully_qualified_name.
# allowed_ip_list / blocked_ip_list are the legacy inline approach and can be
# combined with network rules if needed.

resource "snowflake_network_policy" "policies" {
  provider = snowflake.securityadmin
  for_each = var.network_policies

  name = upper(each.key)

  allowed_network_rule_list = [
    for rule_key in each.value.allowed_network_rule_keys :
    snowflake_network_rule.rules[rule_key].fully_qualified_name
  ]

  blocked_network_rule_list = [
    for rule_key in each.value.blocked_network_rule_keys :
    snowflake_network_rule.rules[rule_key].fully_qualified_name
  ]

  allowed_ip_list = toset(each.value.allowed_ip_list)
  blocked_ip_list = toset(each.value.blocked_ip_list)
  comment         = each.value.comment

  depends_on = [snowflake_network_rule.rules]
}

# ──────────────────────────────────────────────────────────────────────────────
# 4. Account-level attachment (opt-in, disabled by default)
# ──────────────────────────────────────────────────────────────────────────────
# ⚠️  Sets the network policy for THE ENTIRE ACCOUNT.
#     The Terraform runner IP MUST be covered by the chosen policy's allow rules.
#     Wrong config = immediate lockout for everyone.

resource "snowflake_network_policy_attachment" "account" {
  provider = snowflake.securityadmin
  count    = var.account_network_policy != null ? 1 : 0

  network_policy_name = snowflake_network_policy.policies[var.account_network_policy].name
  set_for_account     = true

  depends_on = [snowflake_network_policy.policies]
}

# ──────────────────────────────────────────────────────────────────────────────
# 5. User-level attachments
# ──────────────────────────────────────────────────────────────────────────────

resource "snowflake_network_policy_attachment" "users" {
  provider = snowflake.securityadmin
  for_each = var.user_network_policies

  network_policy_name = snowflake_network_policy.policies[each.value].name
  set_for_account     = false
  users               = [each.key]

  depends_on = [snowflake_network_policy.policies]
}
