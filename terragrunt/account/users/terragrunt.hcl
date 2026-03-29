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

dependency "account_roles" {
  config_path = "${get_repo_root()}/terragrunt/prod/eu-west-2/05-account-roles"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

inputs = {
  snowflake_env = "PROD"

  # Business users are account-level — no env suffix, no service users here
  managed_human_users = include.cfg.locals.human_users
  business_roles      = dependency.account_roles.outputs.business_roles
}
