locals {
  roles = [
    "",
    "ACCOUNTADMIN",
    "SECURITYADMIN",
    "SYSADMIN",
    "USERADMIN",
  ]
  # Separate keys per env in CI: set SNOWFLAKE_USER (e.g. TERRAFORM_DEV / TERRAFORM_PROD); default TERRAFORM.
  terraform_user = get_env("SNOWFLAKE_USER", "TERRAFORM")
  credentials    = get_env("SNOWFLAKE_PRIVATE_KEY")
  account        = get_env("SNOWFLAKE_ACCOUNT_NAME")
  organization   = get_env("SNOWFLAKE_ORGANIZATION_NAME")
}

generate "snowflake_provider" {
  path      = "snowflake_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
%{for role in local.roles~}
provider "snowflake" {
%{if role != ""~}
  alias             = "${lower(role)}"
  role              = "${role}"
%{else~}
  role              = "ACCOUNTADMIN"
%{endif~}

  organization_name = "${local.organization}"
  account_name      = "${local.account}"
  user              = "${local.terraform_user}"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = <<EOT
${trimspace(get_env("SNOWFLAKE_PRIVATE_KEY"))}
EOT

  preview_features_enabled = [
    "snowflake_network_rule_resource",
    "snowflake_network_policy_attachment_resource",
    "snowflake_storage_integration_resource"
  ]
}
%{endfor~}
EOF
}
