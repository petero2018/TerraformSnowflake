# Root config for account-level stacks.
# These run once against the single Snowflake account (no env suffix).
# Business users, resource monitors, network policies, account parameters etc.

locals {
  module_name = basename(get_terragrunt_dir())

  # Explicit workspace name map — keeps HCP Terraform workspace names stable
  # even when stack folder names change (e.g. adding numeric prefixes).
  workspace_name_map = {
    "10-admin-database"           = "admin-database"
    "11-account-database-roles"   = "account-database-roles"
    "20-admin-schemas"            = "admin-schemas"
    "30-users"                    = "users"
    "40-network-policies"         = "network-policies"
    "50-resource-monitors"        = "resource-monitors"
    "account-database-role-grants" = "account-database-role-grants"
  }

  workspace = "king-snowflake-account-${lookup(local.workspace_name_map, local.module_name, local.module_name)}"

  # Account-level stacks always operate against PROD roles/warehouses
  env_lower = "prod"
  env_upper = "PROD"
}

generate "tfc_backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      cloud {
        hostname     = "app.terraform.io"
        organization = "POWISE"
        workspaces { name = "${local.workspace}" }
      }
    }
  EOF
}
