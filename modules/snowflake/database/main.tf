locals {
  # Map logical key → actual Snowflake name, e.g. "bronze" → "BRONZE_DEV"
  db_names = {
    for key, cfg in var.databases :
    key => "${upper(lookup(var.name_overrides, key, key))}_${var.snowflake_env}"
  }
}

resource "snowflake_database" "databases" {
  provider = snowflake.sysadmin
  for_each = var.databases

  name    = local.db_names[each.key]
  comment = each.value.comment
  is_transient = each.value.transient

  data_retention_time_in_days = each.value.data_retention_days
}
