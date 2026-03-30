# ──────────────────────────────────────────────────────────────────────────────
# Container for network rules (schema-level objects)
# ──────────────────────────────────────────────────────────────────────────────
# Network rules are schema-scoped: they live inside a database.schema.
# The schema is created by the 02-schemas stack — this module only references it.
# Caller must pass the fully resolved Snowflake name (e.g. "ADMIN_PROD").

variable "security_database" {
  description = "Fully resolved Snowflake database name where network rules live (e.g. ADMIN_PROD)."
  type        = string
}

variable "security_schema" {
  description = "Schema name inside security_database where network rules live (e.g. NETWORK_POLICY)."
  type        = string
}

# ──────────────────────────────────────────────────────────────────────────────
# Network rules
# ──────────────────────────────────────────────────────────────────────────────
# Each rule has:
#   type:       IPV4 | HOST_PORT | AWSVPCEID | AZURELINKID | GCPPSCID | PRIVATE_HOST_PORT
#   mode:       INGRESS | INTERNAL_STAGE | EGRESS | POSTGRES_INGRESS | POSTGRES_EGRESS
#   value_list: list of IP/CIDR (for IPV4) or hostname:port (for HOST_PORT) strings
#
# name = upper(key)  →  "office_ips" → "OFFICE_IPS"
#
# INGRESS rules restrict who can connect to Snowflake.
# EGRESS rules restrict where Snowflake can connect out to.
#
# Example:
#   network_rules:
#     office_ips:
#       type: IPV4
#       mode: INGRESS
#       value_list: ["203.0.113.0/24", "198.51.100.42"]
#       comment: "Corporate office and VPN"
variable "network_rules" {
  description = "Map of rule key → config. Name will be uppercased."
  type = map(object({
    type       = string           # IPV4 | HOST_PORT | ...
    mode       = string           # INGRESS | EGRESS | ...
    value_list = list(string)
    comment    = optional(string, "")
  }))
  default = {}
}

# ──────────────────────────────────────────────────────────────────────────────
# Policy definitions
# ──────────────────────────────────────────────────────────────────────────────
# Policies reference rule keys from var.network_rules via fully_qualified_name.
# allowed_network_rule_keys / blocked_network_rule_keys must be keys in var.network_rules.
#
# allowed_ip_list / blocked_ip_list are the legacy inline IP approach — still
# supported by Snowflake but prefer network rules for new policies.
#
# name = upper(key)  →  "main" → "MAIN"
#
# Example:
#   network_policies:
#     main:
#       allowed_network_rule_keys: [office_ips]
#       blocked_network_rule_keys: []
#       allowed_ip_list: []
#       blocked_ip_list: []
#       comment: "Primary account policy"
variable "network_policies" {
  description = "Map of policy key → config. Policy names will be uppercased."
  type = map(object({
    allowed_network_rule_keys = optional(list(string), [])
    blocked_network_rule_keys = optional(list(string), [])
    allowed_ip_list           = optional(list(string), [])
    blocked_ip_list           = optional(list(string), [])
    comment                   = optional(string, "")
  }))
  default = {}
}

# ──────────────────────────────────────────────────────────────────────────────
# Account-level attachment
# ──────────────────────────────────────────────────────────────────────────────
# ⚠️  SAFETY GATE — defaults to null (disabled).
# Only set after verifying the Terraform runner IP is in the policy's allowed rules.
# Setting this incorrectly locks everyone out of the account immediately.
variable "account_network_policy" {
  description = <<-EOT
    Key of the network policy (from var.network_policies) to attach to the
    entire Snowflake account.  Defaults to null (no account-level attachment).

    ⚠️  WARNING: The IP running terraform apply MUST be covered by the chosen
    policy's allowed rules.  Wrong config = immediate account lockout.
  EOT
  type    = string
  default = null
}

# ──────────────────────────────────────────────────────────────────────────────
# User-level attachments
# ──────────────────────────────────────────────────────────────────────────────
# Map of Snowflake user name → policy key (from var.network_policies).
variable "user_network_policies" {
  description = "Map of Snowflake user name → network policy key."
  type        = map(string)
  default     = {}
}
