resource "snowflake_grant_privileges_to_database_role" "table_view_grants_all" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.table_view_grants : k => v if v.all_privs }
  database_role_name = snowflake_database_role.db_roles[each.value.role_id].fully_qualified_name
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

resource "snowflake_grant_privileges_to_database_role" "table_view_grants_select" {
  provider           = snowflake.securityadmin
  for_each           = { for k, v in local.table_view_grants : k => v if !v.all_privs }
  database_role_name = snowflake_database_role.db_roles[each.value.role_id].fully_qualified_name
  with_grant_option  = false

  privileges = each.value.privileges

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
