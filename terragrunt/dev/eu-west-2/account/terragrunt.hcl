include "root" {
  path   = find_in_parent_folders()
  expose = true
}
include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/account"
}

locals {
  env_lower = include.root.locals.env_lower
  env_upper = include.root.locals.env_upper
  cfg       = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

inputs = {
  users = local.cfg.users
}
