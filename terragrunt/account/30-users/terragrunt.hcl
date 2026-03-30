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
  mock_outputs                            = { business_roles = {} }
}

dependency "prod_account_roles" {
  config_path = "${get_repo_root()}/terragrunt/prod/eu-west-2/05-account-roles"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs                            = { business_roles = {} }
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

inputs = {
  snowflake_env       = "PROD"
  managed_human_users = include.cfg.locals.global_human_users

  # Merge only the env role outputs that users have requested via grant_envs.
  # If an env stack hasn't been applied yet its output is {} → no grant created (guard in module).
  business_roles = merge(
    anytrue([for u in values(include.cfg.locals.global_human_users) : contains(try(u.grant_envs, []), "dev")])
      ? dependency.dev_account_roles.outputs.business_roles : {},
    anytrue([for u in values(include.cfg.locals.global_human_users) : contains(try(u.grant_envs, []), "prod")])
      ? dependency.prod_account_roles.outputs.business_roles : {},
  )
}
