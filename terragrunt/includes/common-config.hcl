# Common YAML loader for all new modular stacks.
# Each stack includes this file and accesses locals.common.<key>.
locals {
  common_dir        = "${get_repo_root()}/terragrunt/common"
  env_common_dir    = "${get_repo_root()}/terragrunt/common/env"
  global_common_dir = "${get_repo_root()}/terragrunt/common/global"

  # Derive env from the stack's absolute path relative to the repo root
  # e.g. .../terragrunt/dev/eu-west-2/08-users → "dev"
  _rel  = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terragrunt/")
  _env  = lower(element(split("/", local._rel), 0))

  # ── Env-specific ────────────────────────────────────────────────────────
  databases   = yamldecode(file("${local.env_common_dir}/databases.yaml")).databases
  schemas     = yamldecode(file("${local.env_common_dir}/schemas.yaml")).schemas
  warehouses  = yamldecode(file("${local.env_common_dir}/warehouses.yaml"))
  db_roles    = yamldecode(file("${local.env_common_dir}/database_roles.yaml"))
  acc_roles   = yamldecode(file("${local.env_common_dir}/account_roles.yaml"))
  svc_users         = yamldecode(file("${local.env_common_dir}/service_users.yaml")).service_users
  resource_monitors = yamldecode(file("${local.env_common_dir}/resource_monitors.yaml")).resource_monitors
  net_policies      = yamldecode(file("${local.env_common_dir}/network_policies.yaml"))
  net_attach_dev    = yamldecode(file("${local.env_common_dir}/network_policy_attachments_dev.yaml"))
  net_attach_prod   = yamldecode(file("${local.env_common_dir}/network_policy_attachments_prod.yaml"))

  # ── Global (env-agnostic) ───────────────────────────────────────────────
  global_databases     = yamldecode(file("${local.global_common_dir}/databases.yaml")).databases
  global_schemas       = yamldecode(file("${local.global_common_dir}/schemas.yaml")).schemas
  global_db_roles      = yamldecode(file("${local.global_common_dir}/database_roles.yaml"))
  global_role_grants   = yamldecode(file("${local.global_common_dir}/role_grants.yaml")).grants
  global_human_users   = yamldecode(file("${local.global_common_dir}/human_users.yaml")).human_users
}
