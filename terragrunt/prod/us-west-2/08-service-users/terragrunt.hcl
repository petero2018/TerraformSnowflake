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

# Ordering-only dependencies — no output fetching required.
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../03-warehouses",
    "${get_terragrunt_dir()}/../05-account-roles",
    "${get_terragrunt_dir()}/../09-svc-user-network-policies",
  ]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/user"
}

locals {
  secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/prod.yaml"))
}

inputs = {
  snowflake_env       = include.root.locals.env_upper
  valid_database_keys = keys(include.cfg.locals.databases)

  # network_policy_key is resolved to a Snowflake name inside the module:
  # upper("${network_policy_key}_${snowflake_env}") e.g. "SVC_USERS_PROD"
  service_users = include.cfg.locals.svc_users

  service_user_public_keys = local.secrets.service_user_public_keys
}
