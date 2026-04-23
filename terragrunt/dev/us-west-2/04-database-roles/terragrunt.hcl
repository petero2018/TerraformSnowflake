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
    "${get_terragrunt_dir()}/../01-databases",
    "${get_terragrunt_dir()}/../02-schemas",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/database_role"
}

inputs = {
  snowflake_env        = include.root.locals.env_upper
  valid_database_keys  = keys(include.cfg.locals.databases)
  privilege_profiles   = include.cfg.locals.db_roles.privilege_profiles
  database_role_config = include.cfg.locals.db_roles.databases
}
