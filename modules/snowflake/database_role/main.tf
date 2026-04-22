# ──────────────────────────────────────────────────────────────────────────
# Database roles
# Two resource blocks for lifecycle — Terraform cannot make prevent_destroy dynamic.
#   db_roles      → DEV only           (prevent_destroy = false)
#   db_roles_prod → PROD + global ("")  (prevent_destroy = false, temporarily disabled for destroy)
# All downstream grant resources reference local.all_db_roles which merges both.
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env == "DEV" ? local.role_matrix : {}

  database = local.db_names[each.value.db_key]
  name     = each.value.role_name
  comment  = each.value.comment

  lifecycle {
    prevent_destroy = false
  }
}

resource "snowflake_database_role" "db_roles_prod" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env != "DEV" ? local.role_matrix : {}

  database = local.db_names[each.value.db_key]
  name     = each.value.role_name
  comment  = each.value.comment

  lifecycle {
    # prevent_destroy = true  # TODO: re-enable after full re-apply
    prevent_destroy = false
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Grant each database role to super-admin account roles (default: SYSADMIN)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_database_role" "to_super_admins" {
  provider           = snowflake.securityadmin
  for_each           = local.super_admin_bindings
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  parent_role_name   = each.value.admin
}

# ──────────────────────────────────────────────────────────────────────────
# Database-level privileges
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "db_privileges" {
  provider           = snowflake.securityadmin
  for_each           = local.role_matrix
  database_role_name = local.all_db_roles[each.key].fully_qualified_name
  on_database        = local.db_names[each.value.db_key]
  with_grant_option  = false
  privileges         = each.value.database_privileges
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-level privileges (all existing + future schemas in the database)
# Only for roles with NO allowed_schemas (database-scoped)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "schema_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.db_scoped_roles : k => v if length(v.schema_privileges) > 0 }
  database_role_name = local.all_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.schema_privileges

  on_schema {
    all_schemas_in_database = local.db_names[each.value.db_key]
  }
}

resource "snowflake_grant_privileges_to_database_role" "schema_future_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.db_scoped_roles : k => v if length(v.schema_privileges) > 0 }
  database_role_name = local.all_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.schema_privileges

  on_schema {
    future_schemas_in_database = local.db_names[each.value.db_key]
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-level privileges — specific schemas (allowed_schemas is set)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "specific_schema_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.schema_grants : k => v if length(v.privileges) > 0 }
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema {
    schema_name = "${local.db_names[each.value.db_key]}.${each.value.schema_name}"
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-object privileges (all existing + future, per object type)
# Only for roles with NO allowed_schemas (database-scoped)
# ["ALL"] → all_privileges = true
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "object_all_privs" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_grants : k => v if v.all_privs }
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = local.db_names[each.value.db_key]
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = local.db_names[each.value.db_key]
      }
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "object_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_grants : k => v if !v.all_privs }
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = local.db_names[each.value.db_key]
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = local.db_names[each.value.db_key]
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-object privileges — specific schemas (allowed_schemas is set)
# ["ALL"] → all_privileges = true
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "specific_object_all_privs" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_schema_grants : k => v if v.all_privs }
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${local.db_names[each.value.db_key]}.${each.value.schema_name}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${local.db_names[each.value.db_key]}.${each.value.schema_name}"
      }
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "specific_object_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_schema_grants : k => v if !v.all_privs }
  database_role_name = local.all_db_roles[each.value.id_rm].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${local.db_names[each.value.db_key]}.${each.value.schema_name}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${local.db_names[each.value.db_key]}.${each.value.schema_name}"
      }
    }
  }
}
