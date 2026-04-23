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

dependencies {
  paths = ["${get_repo_root()}/terragrunt/account/11-account-database-roles"]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/role_grant"
}

inputs = {
  snowflake_env       = ""
  valid_database_keys = keys(include.cfg.locals.global_databases)
  db_role_config      = include.cfg.locals.global_db_roles.databases
  grants              = include.cfg.locals.global_role_grants
}
