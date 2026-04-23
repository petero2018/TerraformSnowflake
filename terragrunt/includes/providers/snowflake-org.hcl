# Provider include for org-level stacks.
# Requires ORGADMIN role — used only in terragrunt/org/ stacks.
# The SNOWFLAKE_USER referenced here must be an ORGADMIN in your Snowflake organization.
# Typically this is a dedicated terraform_orgadmin service user created manually once.

locals {
  terraform_user = coalesce(
    get_env("SNOWFLAKE_USER_ORG", ""),
    get_env("SNOWFLAKE_USER", "TERRAFORM"),
  )
  account      = get_env("SNOWFLAKE_ACCOUNT_NAME")
  organization = get_env("SNOWFLAKE_ORGANIZATION_NAME")
}

generate "snowflake_org_provider" {
  path      = "snowflake_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "snowflake" {
  alias             = "orgadmin"
  role              = "ORGADMIN"
  organization_name = "${local.organization}"
  account_name      = "${local.account}"
  user              = "${local.terraform_user}"
  authenticator     = "SNOWFLAKE_JWT"
}

# Default provider alias (required by Terraform even if unused)
provider "snowflake" {
  role              = "ORGADMIN"
  organization_name = "${local.organization}"
  account_name      = "${local.account}"
  user              = "${local.terraform_user}"
  authenticator     = "SNOWFLAKE_JWT"
}
EOF
}
