// Databases are generated from var.databases (see 00-variables.tf) and local.db_name_prefix (01-locals.tf).
// Extend by adding a new key in var.databases and a matching prefix in locals.
resource "snowflake_database" "databases" {
  provider = snowflake.sysadmin
  for_each = local.dbs
  name     = each.value.name
  comment  = each.value.comment
}
