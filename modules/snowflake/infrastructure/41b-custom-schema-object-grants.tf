// Custom, YAML-driven schema-object grants per database role, with optional schema scoping
locals {
  // If any entry sets override_defaults for a (db,kind), skip module default grants for that pair
  override_role_keys = toset([
    for e in var.schema_object_grants : "${e.db}|${upper(e.kind)}" if try(e.override_defaults, false)
  ])

  // Expand entries; support object_type="*" to fan out over configured object_types
  schema_object_grants_expanded = {
    for g in flatten([
      for e in var.schema_object_grants : [
        for ot in (e.object_type == "*" ? local.object_types : [e.object_type]) : {
          id         = "${e.db}|${upper(e.kind)}|${ot}|${lower(e.schema == null ? "" : e.schema)}|${lower(e.scope == null ? "all" : e.scope)}|${tostring(coalesce(e.all_privileges, false))}"
          db_key     = e.db
          role_key   = "${e.db}|${upper(e.kind)}"
          object     = ot
          scope      = e.scope == null ? "all" : e.scope
          schema     = e.schema
          all_privs  = coalesce(e.all_privileges, false)
          privileges = try(e.privileges, null)
        }
      ]
    ]) : g.id => g
  }
}

// All-privileges flavor (database scope)
resource "snowflake_grant_privileges_to_database_role" "custom_schema_all_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.schema_object_grants_expanded : k => v if v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  with_grant_option  = false

  all_privileges = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
  }
}

// All-privileges flavor (schema scope)
resource "snowflake_grant_privileges_to_database_role" "custom_schema_all_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.schema_object_grants_expanded : k => v if v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  with_grant_option  = false

  all_privileges = true

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}

// Explicit privileges flavor (granular control)
// Explicit privileges flavor (database scope)
resource "snowflake_grant_privileges_to_database_role" "custom_schema_privs_db" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.schema_object_grants_expanded : k => v if !v.all_privs && v.schema == null }
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  with_grant_option  = false

  privileges = coalesce(
    each.value.privileges,
    lookup(local.object_read_privileges, each.value.object, ["SELECT"]) 
  )

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_database        = snowflake_database.databases[each.value.db_key].name
      }
    }
  }
}

// Explicit privileges flavor (schema scope)
resource "snowflake_grant_privileges_to_database_role" "custom_schema_privs_schema" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.schema_object_grants_expanded : k => v if !v.all_privs && v.schema != null }
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  with_grant_option  = false

  privileges = coalesce(
    each.value.privileges,
    lookup(local.object_read_privileges, each.value.object, ["SELECT"]) 
  )

  on_schema_object {
    dynamic "all" {
      for_each = each.value.scope == "all" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
    dynamic "future" {
      for_each = each.value.scope == "future" ? [1] : []
      content {
        object_type_plural = each.value.object
        in_schema          = "${snowflake_database.databases[each.value.db_key].name}.${each.value.schema}"
      }
    }
  }
}
