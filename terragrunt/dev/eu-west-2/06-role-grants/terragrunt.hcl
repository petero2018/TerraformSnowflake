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
  config_path  = "${get_terragrunt_dir()}/../04-database-roles"
  skip_outputs = tobool(get_env("TG_SKIP_OUTPUTS", "false"))
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = { database_roles = {} }
}

dependency "account_roles" {
  config_path  = "${get_terragrunt_dir()}/../05-account-roles"
  skip_outputs = tobool(get_env("TG_SKIP_OUTPUTS", "false"))
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = { technical_roles = {}, business_roles = {} }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/role_grant"
}

locals {
  _rel = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terragrunt/")
  env  = lower(element(split("/", local._rel), 0))
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Live outputs from upstream stacks
  database_roles  = dependency.database_roles.outputs.database_roles
  technical_roles = dependency.account_roles.outputs.technical_roles
  business_roles  = dependency.account_roles.outputs.business_roles

  # Grant maps derived from account_roles.yaml database_access.
  # Both technical and business roles support per-env map (gold: {dev: READ_WRITE, prod: READ}).
  # try(db_v[env], db_v) falls back to plain string for non-mapped entries.
  technical_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.technical_roles :
    key => {
      for db_k, db_v in try(cfg.database_access, {}) :
      db_k => try(db_v[local.env], db_v)
    }
  }

  # business_roles support per-env map (gold: {dev: READ_WRITE, prod: READ}).
  business_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.business_roles :
    key => {
      for db_k, db_v in try(cfg.database_access, {}) :
      db_k => try(db_v[local.env], db_v)
    }
  }
}
