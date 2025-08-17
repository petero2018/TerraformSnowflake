include "root" { path = find_in_parent_folders() }

terraform {
  # path from this stack to your module
  source = "../../../../modules/snowflake/account"
}
