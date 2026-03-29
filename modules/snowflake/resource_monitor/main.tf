resource "snowflake_resource_monitor" "monitors" {
  provider = snowflake.accountadmin
  for_each = var.resource_monitors

  name         = upper(each.key)
  credit_quota = each.value.credit_quota

  frequency       = each.value.frequency
  start_timestamp = each.value.start_timestamp
  end_timestamp   = each.value.end_timestamp

  notify_triggers           = toset(each.value.notify_triggers)
  suspend_trigger           = each.value.suspend_trigger
  suspend_immediate_trigger = each.value.suspend_immediate_trigger

  notify_users = toset(each.value.notify_users)
}
