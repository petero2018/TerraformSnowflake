# Common YAML loader for all new modular stacks.
# Each stack includes this file and accesses locals.common.<key>.
locals {
  common_dir = "${get_repo_root()}/terragrunt/common"

  databases   = yamldecode(file("${local.common_dir}/databases.yaml")).databases
  schemas     = yamldecode(file("${local.common_dir}/schemas.yaml")).schemas
  warehouses  = yamldecode(file("${local.common_dir}/warehouses.yaml"))
  db_roles    = yamldecode(file("${local.common_dir}/database_roles.yaml"))
  acc_roles   = yamldecode(file("${local.common_dir}/account_roles.yaml"))
  svc_users   = yamldecode(file("${local.common_dir}/service_users.yaml")).service_users
  human_users = yamldecode(file("${local.common_dir}/human_users.yaml")).human_users
}
