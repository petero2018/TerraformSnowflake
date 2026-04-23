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
  paths = ["${get_terragrunt_dir()}/../01-databases"]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/schema"
}

inputs = {
  snowflake_env       = include.root.locals.env_upper
  schemas             = include.cfg.locals.schemas
  valid_database_keys = keys(include.cfg.locals.databases)
}
