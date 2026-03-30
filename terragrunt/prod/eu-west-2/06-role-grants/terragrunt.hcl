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

dependency "database_roles" {
  config_path = "${get_terragrunt_dir()}/../04-database-roles"
}

dependency "account_roles" {
  config_path = "${get_terragrunt_dir()}/../05-account-roles"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/role_grant"
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Live outputs from upstream stacks
  database_roles  = dependency.database_roles.outputs.database_roles
  technical_roles = dependency.account_roles.outputs.technical_roles
  business_roles  = dependency.account_roles.outputs.business_roles

  # Grant maps derived from account_roles.yaml database_access
  technical_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.technical_roles :
    key => try(cfg.database_access, {})
  }
  business_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.business_roles :
    key => try(cfg.database_access, {})
  }
}
