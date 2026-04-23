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

# Ordering-only — human users must be granted roles after env role stacks are applied.
dependencies {
  paths = [
    "${get_repo_root()}/terragrunt/dev/us-west-2/05-account-roles",
    "${get_repo_root()}/terragrunt/prod/us-west-2/05-account-roles",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

inputs = {
  snowflake_env       = "PROD"
  managed_human_users = include.cfg.locals.global_human_users

  # Business role names are computed inside the module using the standard pattern:
  # BUSINESS_ACCOUNT_ROLE_<ROLE_KEY>_<ENV>
  # No cross-stack output dependency needed.
}
