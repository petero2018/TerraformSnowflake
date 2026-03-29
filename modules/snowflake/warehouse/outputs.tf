output "warehouses" {
  description = "Map of logical key → Snowflake warehouse attributes"
  value = {
    for key, wh in snowflake_warehouse.warehouses :
    key => {
      name                 = wh.name
      fully_qualified_name = wh.fully_qualified_name
    }
  }
}
