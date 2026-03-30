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

dependency "schemas" {
  config_path = "${get_terragrunt_dir()}/../02-schemas"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/database_role"
}

inputs = {
  snowflake_env        = include.root.locals.env_upper
  databases            = dependency.databases.outputs.databases
  schemas              = dependency.schemas.outputs.schemas
  privilege_profiles   = include.cfg.locals.db_roles.privilege_profiles
  database_role_config = include.cfg.locals.db_roles.databases
}
