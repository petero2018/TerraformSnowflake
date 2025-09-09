include "root" {
  path   = "${get_repo_root()}/terragrunt/terragrunt.hcl"
  expose = true
}

include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

terraform {
  source = "${get_repo_root()}/modules/snowflake/infrastructure"
}

locals {
  env_lower = include.root.locals.env_lower
  env_upper = include.root.locals.env_upper
  cfg = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

inputs = {
  snowflake_env    = local.env_upper
  databases        = local.cfg.databases
  warehouses       = local.cfg.warehouses
  technical_roles  = local.cfg.technical_roles
  business_roles   = try(local.cfg.business_roles, {})
  service_users    = try(local.cfg.service_users, {})
  tech_role_user_grants = try(local.cfg.tech_role_user_grants, {})
  business_role_user_grants = try(local.cfg.business_role_user_grants, {})
  schema_object_grants = try(local.cfg.schema_object_grants, [])
  schemas = try(local.cfg.schemas, {})
  schema_privileges = try(local.cfg.schema_privileges, [])
  schema_role_privileges = try(local.cfg.schema_role_privileges, {})
  object_types_for_grants = try(local.cfg.object_types_for_grants, ["TABLES", "VIEWS"]) 
  # Keys are best injected via environment variables. Example:
  # service_user_public_keys = {
  #   dbt            = get_env("DBT_RSA_PUBLIC_KEY_PEM", null)
  #   dbt_operations = get_env("DBT_OPERATIONS_RSA_PUBLIC_KEY_PEM", null)
  #   fivetran       = get_env("FIVETRAN_RSA_PUBLIC_KEY_PEM", null)
  #   kafka          = get_env("KAFKA_RSA_PUBLIC_KEY_PEM", null)
  #   airflow        = get_env("AIRFLOW_RSA_PUBLIC_KEY_PEM", null)
  #   looker         = get_env("LOOKER_RSA_PUBLIC_KEY_PEM", null)
  #   growthbook     = get_env("GROWTHBOOK_RSA_PUBLIC_KEY_PEM", null)
  # }
}
