variable "snowflake_env" {
  type        = string
  description = "Environment in uppercase: DEV or PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# Databases output from the database module:
# { bronze: { name: "BRONZE_DEV", fully_qualified_name: "..." }, ... }
variable "databases" {
  description = "Map of logical database key → database attributes (from database module output)"
  type = map(object({
    name                 = string
    fully_qualified_name = string
  }))
}

# Schemas output from the schema module:
# { "bronze__MY_SCHEMA": { database: "BRONZE_DEV", name: "MY_SCHEMA", fully_qualified_name: "..." }, ... }
variable "schemas" {
  description = "Map of '<db_key>__<schema_name>' → schema attributes (from schema module output)"
  type = map(object({
    database             = string
    name                 = string
    fully_qualified_name = string
  }))
  default = {}
}

# Standard roles to create per database: ["R", "RW"]
variable "standard_roles" {
  description = "List of standard role kinds to create for every database (e.g. R, RW)"
  type        = list(string)
  default     = ["R", "RW"]
}

# Privilege profiles define what each standard role kind receives.
# privilege_profiles:
#   R:
#     database_privileges: [USAGE]
#     schema_privileges:   [USAGE]
#     object_privileges:
#       TABLES:   [SELECT]
#       VIEWS:    [SELECT]
#       STAGES:   [USAGE]
#   RW:
#     database_privileges: [USAGE]
#     schema_privileges:   [USAGE, CREATE TABLE, CREATE VIEW]
#     object_privileges:
#       TABLES: all_privileges
#       VIEWS:  all_privileges
variable "privilege_profiles" {
  description = "Per-kind privilege definitions for standard database roles"
  type = map(object({
    database_privileges = list(string)
    schema_privileges   = list(string)
    # object_type → list of privileges, or ["ALL"] to mean all_privileges
    object_privileges = map(list(string))
  }))
  default = {}
}

# List of schema object types to include in grants (controls which object types are iterated)
variable "object_types_for_grants" {
  description = "List of schema object types to grant on (e.g. TABLES, VIEWS, DYNAMIC TABLES)"
  type        = list(string)
  default     = ["TABLES", "VIEWS", "DYNAMIC TABLES", "MATERIALIZED VIEWS", "STAGES", "FILE FORMATS", "EXTERNAL TABLES", "FUNCTIONS", "PIPES", "ICEBERG TABLES"]
}

# custom_roles:
#   gold:
#     RESTRICTED_ALL:
#       comment: "..."
#       grants:
#         - { object_type: "*", scope: all, all_privileges: true }
#         - { object_type: TABLES, schema: REPORTING, scope: all, privileges: [SELECT] }
variable "custom_roles" {
  description = "Per-database custom database roles with explicit schema-object grants (not auto-granted)"
  type = map(map(object({
    name    = optional(string)
    comment = optional(string)
    grants = optional(list(object({
      object_type    = string
      scope          = optional(string, "all")
      schema         = optional(string)
      all_privileges = optional(bool, false)
      privileges     = optional(list(string))
    })), [])
  })))
  default = {}
}

# Super-admin roles to grant each database role to. Defaults to SYSADMIN for all.
# Override per (db, kind) pair:  { "bronze|R": ["SYSADMIN"], "gold|RW": ["SYSADMIN", "ACCOUNTADMIN"] }
variable "super_admin_roles" {
  description = "Map of '<db_key>|<kind>' → list of account role names to receive each database role"
  type        = map(list(string))
  default     = {}
}
