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

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../04-database-roles",
    "${get_terragrunt_dir()}/../05-account-roles",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/role_grant"
}

locals {
  _rel = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terragrunt/")
  env  = lower(element(split("/", local._rel), 0))
}

inputs = {
  snowflake_env       = include.root.locals.env_upper
  valid_database_keys = keys(include.cfg.locals.databases)
  db_role_config      = include.cfg.locals.db_roles.databases

  # Per-env database_access resolution: {dev: READ, prod: READ_WRITE} → flat string for this env
  technical_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.technical_roles :
    key => {
      for db_k, db_v in try(cfg.database_access, {}) :
      db_k => try(db_v[local.env], db_v)
    }
  }

  business_role_grants = {
    for key, cfg in include.cfg.locals.acc_roles.business_roles :
    key => {
      for db_k, db_v in try(cfg.database_access, {}) :
      db_k => try(db_v[local.env], db_v)
    }
  }
}
