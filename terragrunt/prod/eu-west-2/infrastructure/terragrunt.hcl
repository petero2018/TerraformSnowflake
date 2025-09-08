include "root" {
  path   = "${get_repo_root()}/terragrunt/terragrunt.hcl"
  expose = true
}

include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/infrastructure"
}

locals {
  env_lower = include.root.locals.env_lower
  env_upper = include.root.locals.env_upper
}

locals {
  cfg = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

inputs = {
  snowflake_env    = local.env_upper
  databases        = local.cfg.databases
  warehouses       = local.cfg.warehouses
  technical_roles  = local.cfg.technical_roles
}
