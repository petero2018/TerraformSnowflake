resource "snowflake_account_role" "technical" {
  provider = snowflake.securityadmin
  for_each = local.technical_roles_expanded

  name    = each.value.name
  comment = each.value.comment
}

resource "snowflake_account_role" "business" {
  provider = snowflake.securityadmin
  for_each = local.business_roles_expanded

  name    = each.value.name
  comment = each.value.comment
}

# Brief settle pause so Snowflake propagates new roles before grants are applied
resource "time_sleep" "technical_settle" {
  for_each        = local.technical_roles_expanded
  create_duration = "3s"
  depends_on      = [snowflake_account_role.technical]
}

resource "time_sleep" "business_settle" {
  for_each        = local.business_roles_expanded
  create_duration = "3s"
  depends_on      = [snowflake_account_role.business]
}

resource "snowflake_grant_account_role" "technical_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.technical_parent_bindings
  role_name        = snowflake_account_role.technical[each.value.role_key].name
  parent_role_name = each.value.parent
  depends_on       = [time_sleep.technical_settle]
}

resource "snowflake_grant_account_role" "business_to_parent" {
  provider         = snowflake.securityadmin
  for_each         = local.business_parent_bindings
  role_name        = snowflake_account_role.business[each.value.role_key].name
  parent_role_name = each.value.parent
  depends_on       = [time_sleep.business_settle]
}
