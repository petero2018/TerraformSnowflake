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

dependency "databases" {
  config_path = "${get_terragrunt_dir()}/../01-databases"
}

dependency "warehouses" {
  config_path = "${get_terragrunt_dir()}/../03-warehouses"
}

dependency "account_roles" {
  config_path = "${get_terragrunt_dir()}/../05-account-roles"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Live outputs from upstream stacks — contain actual Snowflake names
  databases       = dependency.databases.outputs.databases
  warehouses      = dependency.warehouses.outputs.warehouses
  technical_roles = dependency.account_roles.outputs.technical_roles
  business_roles  = dependency.account_roles.outputs.business_roles

  # Static config from YAML
  service_users       = include.cfg.locals.svc_users
  managed_human_users = include.cfg.locals.human_users
}
