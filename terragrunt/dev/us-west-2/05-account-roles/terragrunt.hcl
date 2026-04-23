include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "snowflake" {
  path = find_in_parent_folders("includes/providers/snowflake.hcl")
}

include "cfg" {
  path   = find_in_parent_folders("includes/common-config.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/account_role"
}

inputs = {
  snowflake_env   = include.root.locals.env_upper
  technical_roles = include.cfg.locals.acc_roles.technical_roles
  business_roles  = include.cfg.locals.acc_roles.business_roles
}
