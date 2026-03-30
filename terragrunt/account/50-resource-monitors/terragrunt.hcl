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
  source = "${get_repo_root()}/modules/snowflake/resource_monitor"
}

inputs = {
  resource_monitors = include.cfg.locals.resource_monitors
}
