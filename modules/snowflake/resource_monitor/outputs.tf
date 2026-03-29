output "resource_monitors" {
  description = "Map of logical key → resource monitor attributes"
  value = {
    for key, rm in snowflake_resource_monitor.monitors :
    key => {
      name                 = rm.name
      fully_qualified_name = rm.fully_qualified_name
    }
  }
}
