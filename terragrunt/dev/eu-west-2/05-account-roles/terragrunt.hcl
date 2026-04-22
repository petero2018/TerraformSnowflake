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

terraform {
  source = "${get_repo_root()}/modules/snowflake/account_role"
}

locals {
  # Derive env from path (same logic as common-config.hcl → always "dev" for this stack)
  _rel = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terragrunt/")
  env  = lower(element(split("/", local._rel), 0))
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Resolve per-env database_access maps.
  # Supports both plain string (gold: READ) and per-env map (gold: {dev: READ_WRITE, prod: READ}).
  # try(db_v[env], db_v) falls back to the plain string for non-mapped entries.
  technical_roles = {
    for rk, rv in include.cfg.locals.acc_roles.technical_roles :
    rk => merge(rv, {
      database_access = {
        for db_k, db_v in try(rv.database_access, {}) :
        db_k => try(db_v[local.env], db_v)
      }
    })
  }

  business_roles = {
    for rk, rv in include.cfg.locals.acc_roles.business_roles :
    rk => merge(rv, {
      database_access = {
        for db_k, db_v in try(rv.database_access, {}) :
        db_k => try(db_v[local.env], db_v)
      }
    })
  }
}
