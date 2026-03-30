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

dependency "dev_account_roles" {
  config_path = "${get_repo_root()}/terragrunt/dev/eu-west-2/05-account-roles"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { business_roles = {} }
}

dependency "prod_account_roles" {
  config_path = "${get_repo_root()}/terragrunt/prod/eu-west-2/05-account-roles"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { business_roles = {} }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

inputs = {
  snowflake_env = "PROD"

  # Business users are account-level — no env suffix, no service users here
  managed_human_users = include.cfg.locals.global_human_users

  # Merge DEV and PROD roles — PROD overwrites DEV if both exist.
  # If only DEV is provisioned → DEV roles are granted.
  # If only PROD is provisioned → PROD roles are granted.
  # If neither → empty map → no grants created (guard in module).
  business_roles = merge(
    dependency.dev_account_roles.outputs.business_roles,
    dependency.prod_account_roles.outputs.business_roles,
  )
}
