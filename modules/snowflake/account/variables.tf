variable "accounts" {
  description = "Map of account key → account configuration."
  type = map(object({
    name                 = string
    admin_name           = string
    admin_password       = optional(string)        # mutually exclusive with admin_rsa_public_key
    admin_rsa_public_key = optional(string)        # preferred over password
    admin_user_type      = optional(string, "SERVICE") # PERSON | SERVICE | LEGACY_SERVICE
    email                = string
    edition              = string                  # STANDARD | ENTERPRISE | BUSINESS_CRITICAL
    region               = string                  # e.g. AWS_US_WEST_2, AZURE_WESTEUROPE
    comment              = optional(string, "")
    must_change_password = optional(bool, false)
    grace_period_in_days = optional(number, 3)     # days before account is permanently deleted after drop
    is_org_admin         = optional(bool, false)   # grant ORGADMIN role to this account
  }))
  default = {}
}
