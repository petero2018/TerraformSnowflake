# Org-level root config — used by all terragrunt/org/ stacks.
# Requires ORGADMIN role (see includes/providers/snowflake-org.hcl).
# TFC workspace prefix: king-snowflake-org-<stack>
#
# ⚠️  Run explicitly via: make docker-org-apply
#     NOT included in docker-apply-all (needs separate ORGADMIN credentials).

locals {
  module_name = basename(get_terragrunt_dir())
  workspace   = "king-snowflake-org-${local.module_name}"

  accounts_yaml = yamldecode(file("${get_repo_root()}/terragrunt/common/org/accounts.yaml"))
  accounts      = local.accounts_yaml.accounts
}

generate "tfc_backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      cloud {
        hostname     = "app.terraform.io"
        organization = "${get_env("TFC_ORGANIZATION")}"
        workspaces { name = "${local.workspace}" }
      }
    }
  EOF
}
