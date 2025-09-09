// Create schemas per database from var.schemas
locals {
  schemas_flat = {
    for s in flatten([
      for db_key, sch_list in var.schemas : [
        for sch in sch_list : {
          id        = "${db_key}|${sch.name}"
          db_key    = db_key
          name      = sch.name
          comment   = try(sch.comment, null)
          is_transient = coalesce(try(sch.is_transient, null), false)
          is_managed   = coalesce(try(sch.is_managed, null), false)
        }
      ]
    ]) : s.id => s
  }
}

resource "snowflake_schema" "schemas" {
  provider = snowflake.sysadmin
  for_each = local.schemas_flat

  database    = snowflake_database.databases[each.value.db_key].name
  name        = each.value.name
  comment     = each.value.comment
  is_transient = each.value.is_transient
}
