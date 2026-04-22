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
  config_path  = "${get_terragrunt_dir()}/../01-databases"
  skip_outputs = tobool(get_env("TG_SKIP_OUTPUTS", "false"))
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = { databases = {} }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/schema"
}

inputs = {
  snowflake_env = include.root.locals.env_upper
  databases     = dependency.databases.outputs.databases
  schemas       = include.cfg.locals.schemas
}
