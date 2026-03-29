variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

variable "warehouses" {
  description = "Map of logical key → warehouse name (from warehouse module output)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
}

variable "technical_roles" {
  description = "Map of logical key → account role attributes (technical)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

variable "business_roles" {
  description = "Map of logical key → account role attributes (business)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# warehouse_grants:
#   transform: [transform]         # technical role keys
#   ingestion:  [ingestion]
#   browse:     [analytics_engineer, data_engineer]  # these are business role keys
variable "technical_warehouse_grants" {
  description = "Map of warehouse key → list of technical role keys to grant USAGE+MONITOR"
  type        = map(list(string))
  default     = {}
}

variable "business_warehouse_grants" {
  description = "Map of warehouse key → list of business role keys to grant USAGE+MONITOR+OPERATE"
  type        = map(list(string))
  default     = {}
}
