# ──────────────────────────────────────────────────────────────────────────
# Standard database roles
# Two blocks for prevent_destroy lifecycle — cannot be dynamic in Terraform.
#   db_roles      → DEV (prevent_destroy = false)
#   db_roles_prod → PROD (prevent_destroy = true)
# All downstream resources reference local.standard_db_roles which merges both.
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_database_role" "db_roles" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env == "PROD" ? {} : local.role_matrix

  database = var.databases[each.value.db_key].fully_qualified_name
  name     = each.value.role_name

  lifecycle {
    prevent_destroy = false
  }
}

resource "snowflake_database_role" "db_roles_prod" {
  provider = snowflake.sysadmin
  for_each = var.snowflake_env == "PROD" ? local.role_matrix : {}

  database = var.databases[each.value.db_key].fully_qualified_name
  name     = each.value.role_name

  lifecycle {
    prevent_destroy = true
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Custom database roles (not auto-granted — opt-in only)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_database_role" "custom_roles" {
  provider = snowflake.sysadmin
  for_each = local.custom_roles_flat

  database = var.databases[each.value.db_key].fully_qualified_name
  name     = each.value.name
  comment  = each.value.comment
}

# ──────────────────────────────────────────────────────────────────────────
# Grant each database role to super-admin account roles (default: SYSADMIN)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_database_role" "to_super_admins" {
  provider           = snowflake.securityadmin
  for_each           = local.super_admin_bindings
  database_role_name = local.standard_db_roles[each.value.pair].fully_qualified_name
  parent_role_name   = each.value.admin
}

# ──────────────────────────────────────────────────────────────────────────
# Database-level privileges
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "db_all" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if v.all_privs }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  on_database        = var.databases[each.value.db_key].name
  with_grant_option  = false
  all_privileges     = true
}

resource "snowflake_grant_privileges_to_database_role" "db_usage" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if !v.all_privs }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  on_database        = var.databases[each.value.db_key].name
  with_grant_option  = false

  privileges = try(var.privilege_profiles[each.value.kind].database_privileges, ["USAGE"])
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-level privileges (on all + future schemas in each database)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "schema_all_privs" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if v.all_privs && try(length(var.privilege_profiles[v.kind].schema_privileges), 0) == 0 }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema {
    all_schemas_in_database = var.databases[each.value.db_key].name
  }
}

resource "snowflake_grant_privileges_to_database_role" "schema_future_all_privs" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if v.all_privs && try(length(var.privilege_profiles[v.kind].schema_privileges), 0) == 0 }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema {
    future_schemas_in_database = var.databases[each.value.db_key].name
  }
}

resource "snowflake_grant_privileges_to_database_role" "schema_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if try(length(var.privilege_profiles[v.kind].schema_privileges), 0) > 0 }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  privileges         = var.privilege_profiles[each.value.kind].schema_privileges

  on_schema {
    all_schemas_in_database = var.databases[each.value.db_key].name
  }
}

resource "snowflake_grant_privileges_to_database_role" "schema_future_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.role_matrix : k => v if try(length(var.privilege_profiles[v.kind].schema_privileges), 0) > 0 }
  database_role_name = local.standard_db_roles[each.key].fully_qualified_name
  with_grant_option  = false
  privileges         = var.privilege_profiles[each.value.kind].schema_privileges

  on_schema {
    future_schemas_in_database = var.databases[each.value.db_key].name
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Schema-object privileges (all + future, per object type)
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "object_all_privs" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_grants : k => v if v.all_privs }
  database_role_name = local.standard_db_roles[each.value.pair].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "object_privileges" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.object_grants : k => v if !v.all_privs }
  database_role_name = local.standard_db_roles[each.value.pair].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Custom role grants — all_privileges, database scope
# ──────────────────────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_database_role" "custom_all_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.custom_grants_expanded : k => v if v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.custom_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
  }
}

# Custom role grants — all_privileges, schema scope
resource "snowflake_grant_privileges_to_database_role" "custom_all_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.custom_grants_expanded : k => v if v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.custom_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false
  all_privileges     = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${var.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${var.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}

# Custom role grants — explicit privileges, database scope
resource "snowflake_grant_privileges_to_database_role" "custom_privs_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.custom_grants_expanded : k => v if !v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.custom_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = var.databases[each.value.db_key].name
      }
    }
  }
}

# Custom role grants — explicit privileges, schema scope
resource "snowflake_grant_privileges_to_database_role" "custom_privs_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.custom_grants_expanded : k => v if !v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.custom_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false
  privileges         = each.value.privileges

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${var.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${var.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}
