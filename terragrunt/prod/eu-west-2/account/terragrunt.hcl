include "root" { path = find_in_parent_folders() }
include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

inputs = {
  users = [
    {
      name              = "TEST_USER_ONE"
      default_role      = "TEST_ROLE" # set here if default should be different than PUBLIC - only already existing roles can be used
      default_warehouse = "COMPUTE_WH"
    },
    {
      name              = "TEST_USER_TWO"
      default_role      = "TEST_ROLE" 
      default_warehouse = "COMPUTE_WH"
    }
]
}