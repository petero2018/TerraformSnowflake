include "root" { path   = find_in_parent_folders() }
include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

inputs = {
  users = [
    {
      name              = "DBT_USER"
      default_role      = "TECHNICAL_ROLE_TRANSFORM_PROD" # set here if default should be different than PUBLIC - only already existing roles can be used
      default_warehouse = "TRANFORM_WH_PROD"
      must_change_password = true
      default_secondary_roles_optional = "ALL"
      password = "changeme123!" # only for initial creation, afterwards the user must change it
    },
]
}