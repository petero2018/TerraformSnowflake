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

# Schemas must exist before database roles can reference them
dependencies {
  paths = ["${get_repo_root()}/terragrunt/account/20-admin-schemas"]
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
