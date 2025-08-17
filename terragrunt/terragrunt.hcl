locals {
  # Derive env name from the path (dev/prod)
  rel_path = path_relative_to_include()
  env      = try(regex("(^|/)(dev|prod)(/|$)", local.rel_path)[2], "dev")

  # One workspace per env
  workspace = "snowflake-${local.env}"
}

# Terraform Cloud backend (Terragrunt generates backend.tf in each stack)
remote_state {
  backend = "remote"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    hostname     = "app.terraform.io"
    organization = "POWISE"
    workspaces   = { name = local.workspace }
  }
}

# (Optional) Snowflake provider via env vars — your module can read these as var inputs, or
# you can generate a provider with an include later. Keep this for handy defaults:
inputs = {
  snowflake_role      = "SYSADMIN"
  snowflake_warehouse = "WH_TERRAFORM"
  # If your module expects these as vars, they'll be passed automatically.
  snowflake_user        = get_env("SNOWFLAKE_USER")
  snowflake_account     = get_env("SNOWFLAKE_ACCOUNT")
  snowflake_region      = get_env("SNOWFLAKE_REGION")
  snowflake_private_key = get_env("SNOWFLAKE_PRIVATE_KEY")
}
