# Merged Snowflake YAML for infrastructure stack + derived inputs (see plan: split config, role bundles, derived database_roles).
locals {
  common_dir = "${get_repo_root()}/terragrunt/common/snowflake-infrastructure"
  cfg = merge(
    yamldecode(file("${local.common_dir}/00-foundations.yaml")),
    yamldecode(file("${local.common_dir}/10-warehouse.yaml")),
    yamldecode(file("${local.common_dir}/11-technical-iam.yaml")),
    yamldecode(file("${local.common_dir}/12-business-iam.yaml")),
    yamldecode(file("${local.common_dir}/20-objects.yaml")),
    fileexists("${get_terragrunt_dir()}/overrides.yaml") ? yamldecode(file("${get_terragrunt_dir()}/overrides.yaml")) : {},
  )

  # Named grant lists; technical_roles may set db_role_grants_profile instead of repeating db_role_grants.
  access_profiles = {
    medallion_rw_all = [
      { db = "operations", kind = "RW" },
      { db = "operations", kind = "R" },
      { db = "bronze", kind = "RW" },
      { db = "bronze", kind = "R" },
      { db = "silver", kind = "RW" },
      { db = "silver", kind = "R" },
      { db = "gold", kind = "RW" },
      { db = "gold", kind = "R" },
    ]
    ingestion_bronze_rw_r = [
      { db = "bronze", kind = "RW" },
      { db = "bronze", kind = "R" },
    ]
    gold_read_only = [
      { db = "gold", kind = "R" },
    ]
  }

  database_roles_default = flatten([
    for db_name, _db in local.cfg.databases : [
      for k in try(local.cfg.database_role_defaults.role_kinds, ["R", "RW"]) : merge(
        { db = db_name, kind = k },
        try(local.cfg.database_role_defaults.super_admin_roles, null) != null ? { super_admin_roles = local.cfg.database_role_defaults.super_admin_roles } : {}
      )
    ]
  ])

  database_roles = length(try(local.cfg.database_roles, [])) > 0 ? local.cfg.database_roles : local.database_roles_default

  technical_roles = {
    for k, tr in local.cfg.technical_roles : k => merge(
      { for kk, vv in tr : kk => vv if kk != "db_role_grants_profile" },
      {
        db_role_grants = coalesce(
          try(tr.db_role_grants, null),
          try(local.access_profiles[tr.db_role_grants_profile], null),
          []
        )
      }
    )
  }
}
