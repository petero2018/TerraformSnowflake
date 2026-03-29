locals {
  # Build a map keyed by "<db_key>__<schema_name>" for for_each
  schemas_map = {
    for s in var.schemas :
    "${s.database}__${s.name}" => s
  }
}

resource "snowflake_schema" "schemas" {
  provider = snowflake.sysadmin
  for_each = local.schemas_map

  database     = var.databases[each.value.database].name
  name         = each.value.name
  comment      = each.value.comment
  is_transient = each.value.is_transient
}
