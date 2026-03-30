output "network_rules" {
  description = "Map of logical key → network rule attributes (name, fully_qualified_name)."
  value = {
    for key, nr in snowflake_network_rule.rules :
    key => {
      name                 = nr.name
      fully_qualified_name = nr.fully_qualified_name
    }
  }
}

output "network_policies" {
  description = "Map of logical key → network policy attributes (name, fully_qualified_name)."
  value = {
    for key, np in snowflake_network_policy.policies :
    key => {
      name                 = np.name
      fully_qualified_name = np.fully_qualified_name
    }
  }
}

output "account_policy_attached" {
  description = "The policy key currently attached at account level, or null if none."
  value       = var.account_network_policy
}
