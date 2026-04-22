include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "snowflake" {
  path = "${get_repo_root()}/terragrunt/includes/providers/snowflake.hcl"
}

include "cfg" {
  path   = "${get_repo_root()}/terragrunt/includes/common-config.hcl"
  expose = true
}

dependency "admin_schemas" {
  config_path  = "${get_repo_root()}/terragrunt/account/20-admin-schemas"
  skip_outputs = tobool(get_env("TG_SKIP_OUTPUTS", "false"))

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    schemas = {}
  }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/database_role"
}

inputs = {
  # snowflake_env = "" → global/agnostic mode: no ENV in role names, prevent_destroy = true
  snowflake_env        = ""
  valid_database_keys  = keys(include.cfg.locals.global_databases)
  name_overrides       = {}
  privilege_profiles   = include.cfg.locals.global_db_roles.privilege_profiles
  database_role_config = include.cfg.locals.global_db_roles.databases
}
