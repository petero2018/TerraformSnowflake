locals {
  roles = [
    "",
    "ACCOUNTADMIN",
    "SECURITYADMIN",
    "SYSADMIN",
    "USERADMIN",
  ]
  # Set TF_ENV=dev|prod (via make load-env) to select the right user.
  # SNOWFLAKE_PRIVATE_KEY is read directly by the provider from the env var.
  _env_upper = upper(get_env("TF_ENV", "dev"))

  terraform_user = coalesce(
    get_env("SNOWFLAKE_USER_${local._env_upper}", ""),
    get_env("SNOWFLAKE_USER", "TERRAFORM"),
  )
  account      = get_env("SNOWFLAKE_ACCOUNT_NAME")
  organization = get_env("SNOWFLAKE_ORGANIZATION_NAME")
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
}
%{endfor~}
EOF
}
