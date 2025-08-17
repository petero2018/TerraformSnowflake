include "root" { path = find_in_parent_folders() }
include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

inputs = {
  account        = get_env("SNOWFLAKE_ACCOUNT_NAME", "")
  organization   = get_env("SNOWFLAKE_ORGANIZATION_NAME", "")
}
