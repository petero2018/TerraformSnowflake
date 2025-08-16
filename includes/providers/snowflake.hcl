locals {
  roles = [
    "",
    "ACCOUNTADMIN",
    "SECURITYADMIN",
    "SYSADMIN",
    "USERADMIN",
  ]
  user        = "TERRAFORM"
  secrets     = yamldecode(sops_decrypt_file(find_in_parent_folders("sops/secrets.d/snowflake.enc.yaml")))
  credentials = lookup(local.secrets.credentials, local.user)
  account     = lookup(local.secrets, "snowflake_account")
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

  organization_name = "${local.account.organization_name}"
  account_name      = "${local.account.name}"
  user              = "${local.user}"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = <<EOT
${trimspace(local.credentials.private_key)}
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