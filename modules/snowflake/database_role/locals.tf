locals {
  # ──────────────────────────────────────────────────────────────────────────
  # Role matrix — one entry per (database × role_key)
  #
  # Name resolution:
  #   role.role_name set   → use exactly that
  #   snowflake_env set    → DATABASE_ROLE_<DB>_<ENV>_<PROFILE_OR_ROLE_KEY>
  #   snowflake_env == ""  → DATABASE_ROLE_<DB>_<PROFILE_OR_ROLE_KEY>  (global/agnostic)
  #
  # allowed_schemas:
  #   empty list → database-level grants (all schemas, via in_database)
  #   non-empty  → schema-level grants only for the listed schemas
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
            var.snowflake_env == ""
              ? "DATABASE_ROLE_${upper(db_key)}_${upper(replace(coalesce(try(role_cfg.profile, null), role_key), "-", "_"))}"
              : "DATABASE_ROLE_${upper(db_key)}_${var.snowflake_env}_${upper(replace(coalesce(try(role_cfg.profile, null), role_key), "-", "_"))}"
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

          # allowed_schemas: empty = database-level (all schemas), non-empty = schema-level only
          allowed_schemas = try(role_cfg.allowed_schemas, [])
        }
      ]
      if contains(keys(var.databases), db_key)
    ]) :
    entry.id => entry
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Split role_matrix into database-scoped vs schema-scoped
  # ──────────────────────────────────────────────────────────────────────────

  # Roles with NO allowed_schemas → grants go to all schemas via in_database
  db_scoped_roles = {
    for k, v in local.role_matrix : k => v
    if length(v.allowed_schemas) == 0
  }

  # Roles WITH allowed_schemas → grants go to specific schemas only
  schema_scoped_roles = {
    for k, v in local.role_matrix : k => v
    if length(v.allowed_schemas) > 0
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
  # Object grants — database-scoped (allowed_schemas is empty)
  # ──────────────────────────────────────────────────────────────────────────
  scopes = ["all", "future"]

  object_grants = {
    for g in flatten([
      for id, rm in local.db_scoped_roles : [
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
  # Schema-level grants — for roles with allowed_schemas
  # One entry per (role, schema_name) — used for schema_privileges grants
  # ──────────────────────────────────────────────────────────────────────────
  schema_grants = {
    for g in flatten([
      for id, rm in local.schema_scoped_roles : [
        for schema_name in rm.allowed_schemas : {
          id          = "${id}|${upper(schema_name)}"
          id_rm       = id
          db_key      = rm.db_key
          schema_name = upper(schema_name)
          privileges  = rm.schema_privileges
        }
      ]
    ]) : g.id => g
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Object grants — schema-scoped (allowed_schemas is non-empty)
  # One entry per (role, schema_name, object_type, scope)
  # ──────────────────────────────────────────────────────────────────────────
  object_schema_grants = {
    for g in flatten([
      for id, rm in local.schema_scoped_roles : [
        for schema_name in rm.allowed_schemas : [
          for obj_type, privs in rm.object_privileges : [
            for sc in local.scopes : {
              id          = "${id}|${upper(schema_name)}|${obj_type}|${sc}"
              id_rm       = id
              db_key      = rm.db_key
              schema_name = upper(schema_name)
              object      = obj_type
              scope       = sc
              all_privs   = contains(privs, "ALL")
              privileges  = contains(privs, "ALL") ? null : privs
            }
          ]
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
