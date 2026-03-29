variable "resource_monitors" {
  description = <<-EOT
    Map of logical key → resource monitor config.

    Example YAML shape:
      resource_monitors:
        account:
          credit_quota:               500
          frequency:                  MONTHLY
          start_timestamp:            "IMMEDIATELY"
          notify_triggers:            [75, 90, 100]
          suspend_trigger:            110
          suspend_immediate_trigger:  120
          notify_users:               []
          comment:                    "Account-level resource monitor"
  EOT

  type = map(object({
    credit_quota              = optional(number, null)
    frequency                 = optional(string, null)   # MONTHLY | DAILY | WEEKLY | YEARLY | NEVER
    start_timestamp           = optional(string, null)   # "IMMEDIATELY" or "YYYY-MM-DD HH:MM"
    end_timestamp             = optional(string, null)
    notify_triggers           = optional(list(number), [])
    suspend_trigger           = optional(number, null)
    suspend_immediate_trigger = optional(number, null)
    notify_users              = optional(list(string), [])
    comment                   = optional(string, "")
  }))
  default = {}
}
