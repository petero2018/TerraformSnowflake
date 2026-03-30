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

dependency "account_database_roles" {
  config_path = "${get_repo_root()}/terragrunt/account/11-account-database-roles"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    database_roles = {}
  }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/role_grant"
}

inputs = {
  database_roles = dependency.account_database_roles.outputs.database_roles
  grants         = include.cfg.locals.global_role_grants
}
