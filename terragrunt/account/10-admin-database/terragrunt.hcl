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

terraform {
  source = "${get_repo_root()}/modules/snowflake/database"
}

inputs = {
  # snowflake_env is intentionally omitted (defaults to "") so no _DEV/_PROD suffix is added.
  # "account_admin" → "ACCOUNT_ADMIN"
  databases = include.cfg.locals.global_databases
}
