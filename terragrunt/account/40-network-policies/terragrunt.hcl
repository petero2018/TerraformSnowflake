include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "snowflake" {
  path = "${get_repo_root()}/terragrunt/includes/providers/snowflake.hcl"
}

include "cfg" {
  path   = "${get_repo_root()}/terragrunt/includes/common-config.hcl"
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
  # Schema that hosts network rule objects
  security_database = include.cfg.locals.net_policies.security_database
  security_schema   = include.cfg.locals.net_policies.security_schema

  # Network rule definitions (IP/CIDR groupings, schema-scoped)
  network_rules = include.cfg.locals.net_policies.network_rules

  # Policy object definitions — account-level, env-agnostic
  network_policies = include.cfg.locals.net_policies.network_policies

  # ⚠️  Account-level attachment — DISABLED BY DEFAULT.
  # Only enable after verifying the runner IP is covered by the policy's rules.
  account_network_policy = include.cfg.locals.net_policies.account_network_policy

  # Human business users — attached at account level (no env suffix)
  user_network_policies = include.cfg.locals.net_policies.account_user_network_policies
}
