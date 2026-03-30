locals {
  # ──────────────────────────────────────────────────────────────────────────
  # Role matrix — one entry per (database × role_key)
  #
  # Resolves the effective privilege profile for each role:
  #   1. If role.profile is set → use var.privilege_profiles[role.profile]
  #   2. Otherwise → use inline database/schema/object_privileges from the role itself
  #
  # Name resolution:
  #   role.role_name set   → use exactly that
  #   role.role_name unset → DATABASE_ROLE_<DB>_<ENV>_<ROLE_KEY>
  #
  # Only includes databases that are actually deployed (present in var.databases).
  # ──────────────────────────────────────────────────────────────────────────
  role_matrix = {
    for entry in flatten([
      for db_key, db_cfg in var.database_role_config : [
        for role_key, role_cfg in db_cfg.roles : {
          id       = "${db_key}|${upper(role_key)}"
          db_key   = db_key
          role_key = upper(role_key)

          role_name = coalesce(
            try(role_cfg.role_name, null),
            "DATABASE_ROLE_${upper(db_key)}_${var.snowflake_env}_${upper(role_key)}"
          )

          comment = try(
            role_cfg.comment != "" ? role_cfg.comment : null,
            var.privilege_profiles[role_cfg.profile].comment != "" ? var.privilege_profiles[role_cfg.profile].comment : null,
            ""
          )

          # Resolved privileges — profile wins over inline if both are set
          database_privileges = coalesce(
            try(role_cfg.database_privileges, null),
            try(var.privilege_profiles[role_cfg.profile].database_privileges, null),
            ["USAGE"]
          )
          schema_privileges = coalesce(
            try(role_cfg.schema_privileges, null),
            try(var.privilege_profiles[role_cfg.profile].schema_privileges, null),
            ["USAGE"]
          )
          object_privileges = coalesce(
            try(role_cfg.object_privileges, null),
            try(var.privilege_profiles[role_cfg.profile].object_privileges, null),
            {}
          )
        }
      ]
      if contains(keys(var.databases), db_key)
    ]) :
    entry.id => entry
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Super-admin grant bindings: (role_matrix_key, admin_role) tuples
  # ──────────────────────────────────────────────────────────────────────────
  super_admin_bindings = {
    for b in flatten([
      for id, rm in local.role_matrix : [
        for admin in lookup(var.super_admin_roles, id, ["SYSADMIN"]) : {
          id    = "${id}|${admin}"
          id_rm = id
          admin = admin
        }
      ]
    ]) : b.id => b
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Object grants matrix — (role_key, object_type, scope) for all/future
  # Only generated for roles that have object_privileges defined.
  # ──────────────────────────────────────────────────────────────────────────
  scopes = ["all", "future"]

  object_grants = {
    for g in flatten([
      for id, rm in local.role_matrix : [
        for obj_type, privs in rm.object_privileges : [
          for sc in local.scopes : {
            id         = "${id}|${obj_type}|${sc}"
            id_rm      = id
            db_key     = rm.db_key
            object     = obj_type
            scope      = sc
            all_privs  = contains(privs, "ALL")
            privileges = contains(privs, "ALL") ? null : privs
          }
        ]
      ]
    ]) : g.id => g
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Unified db_roles reference — merges dev + prod resource blocks.
  # Used by grant resources to look up fully_qualified_name.
  # ──────────────────────────────────────────────────────────────────────────
  all_db_roles = merge(
    snowflake_database_role.db_roles,
    snowflake_database_role.db_roles_prod,
  )
}
