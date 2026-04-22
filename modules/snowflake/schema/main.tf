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

  # Derive the Snowflake database name from the logical key + env suffix,
  # mirroring the formula in the database module. No cross-stack output needed.
  database     = var.snowflake_env == "" ? upper(lookup(var.name_overrides, each.value.database, each.value.database)) : "${upper(lookup(var.name_overrides, each.value.database, each.value.database))}_${var.snowflake_env}"
  name         = each.value.name
  comment      = each.value.comment
  is_transient = each.value.is_transient
}
