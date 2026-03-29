locals {
  rel_path   = path_relative_to_include()
  first_segment = lower(element(split("/", local.rel_path), 0)) # dev/prod
  env_map    = { dev = "dev", prod = "prod" }
  env_lower  = lookup(local.env_map, local.first_segment, "dev")
  env_upper  = upper(local.env_lower)

  # derive stack name (account/infrastructure/etc.)
  module_name = basename(get_terragrunt_dir())

  # workspace name unique per env + module
  workspace = "king-snowflake-${local.env_lower}-${local.module_name}"
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