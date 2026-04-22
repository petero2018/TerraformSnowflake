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

# Schemas live inside ACCOUNT_ADMIN — database must exist first
dependency "admin_database" {
  config_path  = "${get_repo_root()}/terragrunt/account/10-admin-database"
  skip_outputs = tobool(get_env("TG_SKIP_OUTPUTS", "false"))

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    databases = {
      account_admin = {
        name                 = "ACCOUNT_ADMIN"
        fully_qualified_name = "ACCOUNT_ADMIN"
      }
    }
  }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/schema"
}

inputs = {
  # Schema module requires snowflake_env but uses it only to resolve database names
  # from the dependency output — pass empty string since names are already resolved.
  snowflake_env = ""
  databases     = dependency.admin_database.outputs.databases
  schemas       = include.cfg.locals.global_schemas
}
