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

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../03-warehouses",
    "${get_terragrunt_dir()}/../05-account-roles",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/warehouse_grant"
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  # Names computed from keys — no output fetching needed.
  # warehouse: upper(key)_ENV, technical role: TECHNICAL_ACCOUNT_ROLE_<KEY>_ENV, etc.
  technical_warehouse_grants = include.cfg.locals.warehouses.technical_warehouse_grants
  business_warehouse_grants  = include.cfg.locals.warehouses.business_warehouse_grants
}
