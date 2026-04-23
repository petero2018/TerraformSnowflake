include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "snowflake" {
  path = "${get_repo_root()}/terragrunt/includes/providers/snowflake-org.hcl"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

inputs = {
  accounts = include.root.locals.accounts
}
