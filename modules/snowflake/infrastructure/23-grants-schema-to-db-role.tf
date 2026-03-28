// Schema-level privileges per database role kind (R/RW)
locals {
  schema_privileges_flat = {
    for g in var.schema_privileges :
    "${g.db}|${g.schema}|${upper(g.kind)}" => {
      db_key     = g.db
      schema     = g.schema
      role_key   = "${g.db}|${upper(g.kind)}"
      privileges = g.privileges
      with_grant = try(g.with_grant_option, false)
    }
  }
}

resource "snowflake_grant_privileges_to_database_role" "schema_privileges" {
  provider           = snowflake.securityadmin
  for_each           = local.schema_privileges_flat
  database_role_name = local.db_roles[each.value.role_key].fully_qualified_name
  with_grant_option  = each.value.with_grant

  privileges = each.value.privileges

  on_schema {
    schema_name = snowflake_schema.schemas["${each.value.db_key}|${each.value.schema}"].fully_qualified_name
  }
}

