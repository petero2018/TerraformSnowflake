resource "snowflake_database" "databases" {
  provider = snowflake.sysadmin
  for_each = local.dbs
  name     = each.value.name
  comment  = each.value.comment
}
