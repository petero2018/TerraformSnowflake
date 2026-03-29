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

dependency "databases" {
  config_path = "${get_terragrunt_dir()}/../01-databases"
}

dependency "warehouses" {
  config_path = "${get_terragrunt_dir()}/../03-warehouses"
}

dependency "account_roles" {
  config_path = "${get_terragrunt_dir()}/../05-account-roles"
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/prod.yaml"))
}

inputs = {
  snowflake_env = include.root.locals.env_upper

  databases       = dependency.databases.outputs.databases
  warehouses      = dependency.warehouses.outputs.warehouses
  technical_roles = dependency.account_roles.outputs.technical_roles

  service_users            = include.cfg.locals.svc_users
  service_user_public_keys = local.secrets.service_user_public_keys
}
