include "root" {
  path   = "${get_repo_root()}/terragrunt/terragrunt.hcl"
  expose = true
}

include "snowflake" { path = find_in_parent_folders("includes/providers/snowflake.hcl") }

include "snowflake_infra_config" {
  path   = "${get_repo_root()}/terragrunt/includes/snowflake-infrastructure-config.hcl"
  expose = true
}

dependencies {
  paths = ["${get_terragrunt_dir()}/../account"]
}

terraform {
  source = "${get_repo_root()}/modules/snowflake/infrastructure"
}

inputs = {
  snowflake_env             = include.root.locals.env_upper
  databases                 = include.snowflake_infra_config.locals.cfg.databases
  warehouses                = include.snowflake_infra_config.locals.cfg.warehouses
  warehouse_grants          = try(include.snowflake_infra_config.locals.cfg.warehouse_grants, [])
  technical_roles           = include.snowflake_infra_config.locals.technical_roles
  database_roles            = include.snowflake_infra_config.locals.database_roles
  business_roles            = try(include.snowflake_infra_config.locals.cfg.business_roles, {})
  service_users             = try(include.snowflake_infra_config.locals.cfg.service_users, {})
  tech_role_user_grants     = try(include.snowflake_infra_config.locals.cfg.tech_role_user_grants, {})
  business_role_user_grants = try(include.snowflake_infra_config.locals.cfg.business_role_user_grants, {})
  schema_object_grants      = try(include.snowflake_infra_config.locals.cfg.schema_object_grants, [])
  schemas                   = try(include.snowflake_infra_config.locals.cfg.schemas, {})
  schema_privileges         = try(include.snowflake_infra_config.locals.cfg.schema_privileges, [])
  schema_role_privileges    = try(include.snowflake_infra_config.locals.cfg.schema_role_privileges, {})
  custom_schema_roles       = try(include.snowflake_infra_config.locals.cfg.custom_schema_roles, {})
  object_types_for_grants   = try(include.snowflake_infra_config.locals.cfg.object_types_for_grants, ["TABLES", "VIEWS"])
}
