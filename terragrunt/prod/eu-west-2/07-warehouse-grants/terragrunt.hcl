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

terraform {
  source = "${get_repo_root()}/modules/snowflake/warehouse_grant"
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Live outputs from upstream stacks
  warehouses      = dependency.warehouses.outputs.warehouses
  technical_roles = dependency.account_roles.outputs.technical_roles
  business_roles  = dependency.account_roles.outputs.business_roles

  # Grant maps from warehouses.yaml
  technical_warehouse_grants = include.cfg.locals.warehouses.technical_warehouse_grants
  business_warehouse_grants  = include.cfg.locals.warehouses.business_warehouse_grants
}
