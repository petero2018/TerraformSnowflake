# Root config for account-level stacks.
# These run once against the single Snowflake account (no env suffix).
# Business users, resource monitors, network policies, account parameters etc.

locals {
  module_name = basename(get_terragrunt_dir())
  workspace   = "king-snowflake-account-${local.module_name}"

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
