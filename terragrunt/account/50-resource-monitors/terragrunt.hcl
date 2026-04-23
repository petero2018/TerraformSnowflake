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

# Warehouses must exist before monitors can be attached to them.
# Human users must exist before they can be listed as notify_users.
dependencies {
  paths = [
    "${get_repo_root()}/terragrunt/dev/us-west-2/03-warehouses",
    "${get_repo_root()}/terragrunt/prod/us-west-2/03-warehouses",
    "${get_repo_root()}/terragrunt/account/30-users",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/resource_monitor"
}

inputs = {
  resource_monitors = include.cfg.locals.resource_monitors
}
