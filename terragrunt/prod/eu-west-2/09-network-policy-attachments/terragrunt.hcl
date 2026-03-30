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

# Depends on the account network-policies stack (policies must exist first)
dependency "network_policies" {
  config_path = "${get_repo_root()}/terragrunt/account/40-network-policies"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    network_rules    = {}
    network_policies = {}
  }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/network_policy"
}

inputs = {
  # Schema location — required by the module even though this stack creates no rules
  security_database = include.cfg.locals.net_policies.security_database
  security_schema   = include.cfg.locals.net_policies.security_schema

  # Rules and policies are managed by account/network-policies stack — none here
  network_rules    = {}
  network_policies = {}

  account_network_policy = null

  # PROD service user attachments
  user_network_policies = include.cfg.locals.net_attach_prod.service_user_network_policies
}
