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

dependency "warehouses" {
  config_path = "${get_terragrunt_dir()}/../03-warehouses"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
  mock_outputs = { warehouses = {} }
}

dependency "account_roles" {
  config_path = "${get_terragrunt_dir()}/../05-account-roles"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
  mock_outputs = { technical_roles = {}, business_roles = {} }
}

dependency "network_policies" {
  config_path = "${get_terragrunt_dir()}/../09-svc-user-network-policies"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
  mock_outputs = { network_policies = {} }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/prod.yaml"))
}

inputs = {
  snowflake_env       = include.root.locals.env_upper
  valid_database_keys = keys(include.cfg.locals.databases)
  name_overrides      = { operations = "OPERATION" }

  warehouses      = dependency.warehouses.outputs.warehouses
  technical_roles = dependency.account_roles.outputs.technical_roles

  # Merge the resolved env-specific network policy name into every service user.
  service_users = {
    for k, u in include.cfg.locals.svc_users : k => merge(u, {
      # Policy name includes env suffix: SVC_USERS_DEV / SVC_USERS_PROD
      network_policy = try(dependency.network_policies.outputs.network_policies["svc_users_${lower(include.root.locals.env_lower)}"].name, null)
    })
  }

  service_user_public_keys = local.secrets.service_user_public_keys
}
