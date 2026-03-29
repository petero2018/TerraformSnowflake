locals {
  # ──────────────────────────────────────────────────────────────────────────
  # Standard role matrix: one entry per (database × kind) pair
  # Key format: "<db_key>|<KIND>"  e.g. "bronze|R", "gold|RW"
  # ──────────────────────────────────────────────────────────────────────────
  role_matrix = {
    for pair in flatten([
      for db_key in keys(var.databases) : [
        for kind in var.standard_roles : "${db_key}|${upper(kind)}"
      ]
    ]) :
    pair => {
      db_key    = element(split("|", pair), 0)
      kind      = element(split("|", pair), 1)
      role_name = "DATABASE_ROLE_${upper(element(split("|", pair), 0))}_${var.snowflake_env}_${element(split("|", pair), 1)}"
      all_privs = element(split("|", pair), 1) == "RW"
    }
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Resolved super-admin bindings: each (role_key, admin) tuple
  # ──────────────────────────────────────────────────────────────────────────
  super_admin_bindings = {
    for b in flatten([
      for pair, rm in local.role_matrix : [
        for admin in lookup(var.super_admin_roles, pair, ["SYSADMIN"]) : {
          id    = "${pair}|${admin}"
          pair  = pair
          admin = admin
        }
      ]
    ]) : b.id => b
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Resolved privilege profiles
  # ──────────────────────────────────────────────────────────────────────────
  scopes = ["all", "future"]

  # Which object types to iterate — union of configured + what appears in profiles
  effective_object_types = var.object_types_for_grants

  # Object privileges matrix: (role_key, object_type, scope)
  object_grants = {
    for g in flatten([
      for pair, rm in local.role_matrix : [
        for obj in local.effective_object_types : [
          for sc in local.scopes : {
            id        = "${pair}|${obj}|${sc}"
            pair      = pair
            db_key    = rm.db_key
            kind      = rm.kind
            object    = obj
            scope     = sc
            all_privs = rm.all_privs ? true : (
              # Check if profile explicitly sets ALL for this object type
              contains(lookup(try(var.privilege_profiles[rm.kind].object_privileges, {}), obj, []), "ALL")
            )
            privileges = rm.all_privs ? null : (
              lookup(try(var.privilege_profiles[rm.kind].object_privileges, {}), obj,
                # Sensible defaults when no profile is provided
                contains(["STAGES", "FILE FORMATS", "FUNCTIONS"], obj) ? ["USAGE"] :
                contains(["PIPES"], obj) ? ["MONITOR"] :
                ["SELECT"]
              )
            )
          }
        ]
      ]
    ]) : g.id => g
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Custom roles flat list
  # ──────────────────────────────────────────────────────────────────────────
  custom_roles_flat = {
    for r in flatten([
      for db_key, roles in var.custom_roles : [
        for role_key, rc in roles : {
          id       = "${db_key}|${role_key}"
          db_key   = db_key
          role_key = role_key
          name     = coalesce(try(rc.name, null), "DATABASE_ROLE_${upper(db_key)}_${var.snowflake_env}_${upper(role_key)}")
          comment  = try(rc.comment, null)
          grants   = try(rc.grants, [])
        }
      ]
    ]) : r.id => r
  }

  # Expand custom role grants — support object_type="*"
  custom_grants_expanded = {
    for g in flatten([
      for id, r in local.custom_roles_flat : [
        for grant in r.grants : [
          for ot in (grant.object_type == "*" ? local.effective_object_types : [grant.object_type]) : {
            id         = "${id}|${ot}|${lower(grant.scope == null ? "all" : grant.scope)}|${lower(grant.schema == null ? "" : grant.schema)}|${grant.all_privileges == null ? "false" : tostring(grant.all_privileges)}"
            role_id    = id
            db_key     = r.db_key
            object     = ot
            scope      = try(grant.scope, "all")
            schema     = try(grant.schema, null)
            all_privs  = try(grant.all_privileges, false)
            privileges = try(grant.privileges, null)
          }
        ]
      ]
    ]) : g.id => g
  }

  # ──────────────────────────────────────────────────────────────────────────
  # Unified db_roles for use by other modules (standard + custom)
  # Merges whichever standard resource block is active (dev vs prod) with custom roles.
  # ──────────────────────────────────────────────────────────────────────────
  standard_db_roles = merge(
    snowflake_database_role.db_roles,
    snowflake_database_role.db_roles_prod,
  )

  all_db_roles = merge(
    local.standard_db_roles,
    snowflake_database_role.custom_roles,
  )
}
