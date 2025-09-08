
resource "snowflake_resource_monitor" "overall_credit_monitor" {
  provider     = snowflake.accountadmin
  name         = "rm-overall-credit-monitor"
  credit_quota = 10000

  frequency       = "MONTHLY"
  start_timestamp = substr(replace(timeadd(timestamp(), "1h"), "T", " "), 0, 16)
  end_timestamp   = "2035-12-31 00:00"

  notify_triggers           = [50, 60, 70, 80, 90]
  suspend_trigger           = 80
  suspend_immediate_trigger = 90

  notify_users = ["KINGMATYAS"]
}
