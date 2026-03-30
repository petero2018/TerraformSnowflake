variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# warehouses:
#   transform:
#     size: SMALL
#     comment: "dbt workloads"
#     warehouse_type: STANDARD
#     generation: 1
#     auto_suspend: 120
#     auto_resume: true
#     initially_suspended: true
#     statement_timeout_in_seconds: 108000
#     max_cluster_count: 1          # optional, multi-cluster
#     min_cluster_count: 1          # optional, multi-cluster
#     scaling_policy: STANDARD      # optional, multi-cluster
#     max_concurrency_level: 8      # optional
#     statement_queued_timeout_in_seconds: 0  # optional
variable "warehouses" {
  description = "Map of logical warehouse key → config"
  type = map(object({
    size                                = string
    comment                             = optional(string, "")
    warehouse_type                      = optional(string, "STANDARD")
    generation                          = optional(number, null)
    auto_suspend                        = optional(number, 120)
    auto_resume                         = optional(bool, true)
    initially_suspended                 = optional(bool, true)
    statement_timeout_in_seconds        = optional(number, 7200)
    max_cluster_count                   = optional(number, null)
    min_cluster_count                   = optional(number, null)
    scaling_policy                      = optional(string, null)
    max_concurrency_level               = optional(number, null)
    statement_queued_timeout_in_seconds = optional(number, null)
  }))
}
