# Common YAML loader for all new modular stacks.
# Each stack includes this file and accesses locals.common.<key>.
locals {
  common_dir = "${get_repo_root()}/terragrunt/common"

  # Derive env from the stack's absolute path relative to the repo root
  # e.g. .../terragrunt/dev/eu-west-2/08-users → "dev"
  _rel  = trimprefix(get_terragrunt_dir(), "${get_repo_root()}/terragrunt/")
  _env  = lower(element(split("/", local._rel), 0))

  databases   = yamldecode(file("${local.common_dir}/databases.yaml")).databases
  schemas     = yamldecode(file("${local.common_dir}/schemas.yaml")).schemas
  warehouses  = yamldecode(file("${local.common_dir}/warehouses.yaml"))
  db_roles    = yamldecode(file("${local.common_dir}/database_roles.yaml"))
  acc_roles   = yamldecode(file("${local.common_dir}/account_roles.yaml"))
  svc_users   = yamldecode(file("${local.common_dir}/service_users.yaml")).service_users
  human_users = yamldecode(file("${local.common_dir}/human_users.yaml")).human_users
}
