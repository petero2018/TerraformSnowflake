include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "snowflake" {
  path = find_in_parent_folders("includes/providers/snowflake.hcl")
}

include "cfg" {
  path   = find_in_parent_folders("includes/common-config.hcl")
  expose = true
}

# ACCOUNT_ADMIN.NETWORK_POLICY schema must exist before network rules can be created
dependency "admin_schemas" {
  config_path = "${get_repo_root()}/terragrunt/account/20-admin-schemas"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    schemas = {}
  }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/network_policy"
}

inputs = {
  security_database = upper(include.cfg.locals.svc_net_policies.security_database)
  security_schema   = include.cfg.locals.svc_net_policies.security_schema

  network_rules = {
    for k, r in include.cfg.locals.svc_net_policies.network_rules :
    # Append env suffix to rule key so the Snowflake name is e.g. SVC_USER_IPS_PROD
    "${k}_${lower(include.root.locals.env_lower)}" => r
  }

  network_policies = {
    for k, p in include.cfg.locals.svc_net_policies.network_policies :
    # Append env suffix to policy key so the Snowflake name is e.g. SVC_USERS_PROD
    "${k}_${lower(include.root.locals.env_lower)}" => merge(p, {
      # Rewrite the rule key references to use the suffixed rule names
      allowed_network_rule_keys = [
        for rk in p.allowed_network_rule_keys : "${rk}_${lower(include.root.locals.env_lower)}"
      ]
      blocked_network_rule_keys = [
        for rk in p.blocked_network_rule_keys : "${rk}_${lower(include.root.locals.env_lower)}"
      ]
    })
  }

  # No account-level attachment — these policies are user-level only
  account_network_policy = null
}
