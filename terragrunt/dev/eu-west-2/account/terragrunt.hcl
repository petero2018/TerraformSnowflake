include "root" { path = find_in_parent_folders() }
include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

inputs = {
  test_input_var = "test_value"
}
