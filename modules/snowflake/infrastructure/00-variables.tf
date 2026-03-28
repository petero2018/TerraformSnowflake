# Core environment selector. Extend nothing here; pass DEV/PROD via Terragrunt inputs.
variable "snowflake_env" {
  type        = string
  description = "ENV in caps. Allowed: DEV, PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

# TECHNICAL ROLES
# How to extend:
# - To add a new technical role, add a new key under default (or via Terragrunt inputs), e.g. "mlops".
#   The account role name becomes TECHNICAL_ACCOUNT_ROLE_<KEY_UPPER>_<ENV> automatically.
# - parent_role can be any existing account role you want to grant this under (e.g. SYSADMIN).
# - db_role_grants list controls which database roles are granted to this technical role.
#   - db must match a key from var.databases (e.g. bronze, silver, gold, operations, retl or your custom one)
#   - kind is either "R" (read/SELECT/USAGE) or "RW" (all privileges) and controls both DB-level and table/view grants.
# - super_admin_roles: omit to grant this account role to SYSADMIN; set to [] to skip parent grants; or set explicit parent role names.
# - To remove access, delete the corresponding item from db_role_grants and apply.
variable "technical_roles" {
  description = "Technical account roles, optional super_admin_roles, and database-role grants"
  type = map(object({
    parent_role       = optional(string)       # deprecated; use super_admin_roles
    parent_roles      = optional(list(string)) # deprecated; use super_admin_roles
    super_admin_roles = optional(list(string)) # omit => ["SYSADMIN"]; [] => no parent grants
    db_role_grants    = optional(list(object({ db = string, kind = string })), [])
  }))
  default = {}
}

# BUSINESS ROLES
# Define account-level business roles that are environment-scoped and can be granted to users.
# Example (Terragrunt YAML):
# business_roles:
#   analytics_engineer:
#     parent_role: SYSADMIN
#     db_role_grants:
#       - { db: silver, kind: R }
#       - { db: gold,   kind: R }
variable "business_roles" {
  description = "Business account roles and their database-role grants"
  type = map(object({
    parent_role       = optional(string)       # deprecated; use super_admin_roles
    parent_roles      = optional(list(string)) # deprecated; use super_admin_roles
    super_admin_roles = optional(list(string)) # omit => ["SYSADMIN"]; [] => no parent grants
    db_role_grants    = optional(list(object({ db = string, kind = string })), [])
  }))
  default = {}
}


# DATABASES
# How to extend:
# - Add a new database/layer by adding a new key to this map (or override via Terragrunt inputs).
#   Example key: "platinum" { comment = "...", roles = ["R","RW"] }
# - roles controls which database roles will be created per database:
#   - "R" creates ROLE_<DB>_<ENV>_R and grants USAGE on DB + SELECT on TABLES/VIEWS (now and future)
#   - "RW" creates ROLE_<DB>_<ENV>_RW and grants ALL on DB + ALL on TABLES/VIEWS (now and future)
# - The final Snowflake database name is derived from locals (see 01-locals.tf), following <PREFIX>_<ENV>.
#   If you add a new key, also add an entry to local.db_name_prefix to control its exact prefix.
variable "databases" {
  description = "Databases metadata (no roles here; see database_roles)"
  type = map(object({
    comment = string
  }))
  default = {}
}

# Explicit database roles to create. Each item defines a (db, kind) pair.
# Kinds are open-ended (e.g., R, RW, ANALYTICS_RO).
variable "database_roles" {
  description = "List of database-role specs to create (db, kind) with optional super admins"
  type = list(object({
    db                = string
    kind              = string
    super_admin_roles = optional(list(string)) # omit => ["SYSADMIN"]; [] => do not grant DB role to any parent role
  }))
  default = []
}

# Optional: path to a YAML file containing the full databases map.
# See note under technical_roles_yaml_path regarding Terraform Cloud and module-local files.

# WAREHOUSES
# How to extend:
# - Add a new warehouse key (e.g. "ad_hoc") with size/comment.
# - grantees is a list of technical role keys (from var.technical_roles) that should receive USAGE, MONITOR on this warehouse.
# - The final Snowflake warehouse name is derived as <KEY_UPPER>_WH_<ENV> in locals (see 01-locals.tf).
# - To remove a grant, remove the key from grantees; to remove a warehouse, remove the whole entry.
variable "warehouses" {
  description = "Warehouses to create (grants configured separately via warehouse_grants)"
  type = map(object({
    warehouse_size = string
    comment        = string
  }))
  default = {}
}

# Warehouse → role grants. Allows mapping to technical roles, business roles, or literal account roles.
# Example:
# warehouse_grants:
#   - { warehouse: transform, role_type: "technical", role_keys: ["transform"] }
#   - { warehouse: browse,    role_type: "business",  role_keys: ["analytics_engineer","analyst"] }
#   - { warehouse: special,   role_type: "account",   role_keys: ["SECURITYADMIN"] }
variable "warehouse_grants" {
  description = "List of warehouse grants: (warehouse, role_type: technical|business|account, role_keys)"
  type = list(object({
    warehouse = string
    role_type = string
    role_keys = list(string)
  }))
  default = []
}

// NOTE: We rely on Terragrunt to read YAML and pass maps below as inputs per environment.

# OBJECT TYPES FOR GRANTS
# Control which schema object types receive R/RW grants (now + future) to database roles.
# Common values: "TABLES", "VIEWS", "DYNAMIC TABLES", "MATERIALIZED VIEWS".
# Example (Terragrunt YAML): object_types_for_grants: ["TABLES", "VIEWS", "DYNAMIC TABLES"]
variable "object_types_for_grants" {
  description = "List of schema object types to grant across databases"
  type        = list(string)
  default     = ["TABLES", "VIEWS"]
}

# SCHEMAS
# Define schemas per database key. Example YAML:
# schemas:
#   bronze:
#     - { name: SAMPLE_BRONZE_SCHEMA_ONE, comment: "Sample schema" }
#   silver:
#     - { name: SAMPLE_SILVER_SCHEMA_ONE }
#   gold:
#     - { name: SAMPLE_GOLD_SCHEMA_ONE }
variable "schemas" {
  description = "Schemas to create per database key"
  type = map(list(object({
    name         = string
    comment      = optional(string)
    is_transient = optional(bool, false)
    is_managed   = optional(bool, false) # managed access
  })))
  default = {}
}

# SCHEMA PRIVILEGES (schema-level)
# Configure schema-level privileges per database role kind (R/RW) for a specific schema.
# Example YAML:
# schema_privileges:
#   - { db: gold, schema: SAMPLE_GOLD_SCHEMA_ONE, kind: R,  privileges: ["USAGE"] }
#   - { db: gold, schema: SAMPLE_GOLD_SCHEMA_ONE, kind: RW, privileges: ["USAGE", "CREATE TABLE", "CREATE VIEW"] }
variable "schema_privileges" {
  description = "Schema-level privileges per (db, schema, role kind)"
  type = list(object({
    db                = string
    schema            = string
    kind              = string # "R" or "RW"
    privileges        = list(string)
    with_grant_option = optional(bool, false)
  }))
  default = []
}

# SCHEMA ROLE PRIVILEGES (for auto-created schema roles)
# Configure privileges for custom schema roles per database.
# Example YAML:
# schema_role_privileges:
#   bronze:
#     R:  ["USAGE"]
#     RW: ["USAGE", "CREATE TABLE", "CREATE VIEW"]
#   silver:
#     R:  ["USAGE"]
#     RW: ["USAGE", "CREATE TABLE", "CREATE VIEW"]
#   gold:
#     R:  ["USAGE"]
#     RW: ["USAGE", "CREATE TABLE", "CREATE VIEW"]
variable "schema_role_privileges" {
  description = "Privileges to apply for auto-created schema roles per database (R/RW)"
  type = map(object({
    R  = list(string)
    RW = list(string)
  }))
  default = {}
}

# CUSTOM SCHEMA OBJECT GRANTS
# Fine-grained grants per database role and schema/object type.
# Entries complement or override defaults. Supports wildcard object_type "*" to expand to object_types_for_grants.
# Example (Terragrunt YAML):
# schema_object_grants:
#   - { db: gold, kind: R, object_type: "*", scope: all, all_privileges: true }
#   - { db: gold, kind: R, object_type: "TABLES", scope: all, schema: "REPORTING", privileges: ["SELECT"] }
#   - { db: silver, kind: RW, object_type: "VIEWS", scope: future, schema: "ANALYTICS", privileges: ["SELECT"] }
variable "schema_object_grants" {
  description = "Custom per-role schema-object grants (expands '*' over configured object types)"
  type = list(object({
    db                = string                  # key from var.databases
    kind              = string                  # "R" or "RW"
    object_type       = string                  # e.g. "TABLES", "VIEWS", "*" to expand across object_types_for_grants
    scope             = optional(string, "all") # "all" or "future"
    schema            = optional(string)        # if set, grant in this schema only; otherwise across database
    all_privileges    = optional(bool)          # true => grant all_privileges on schema objects
    privileges        = optional(list(string))  # explicit privileges list when all_privileges is false
    override_defaults = optional(bool, false)   # if true, skip the module's default object grants for this (db,kind)
  }))
  default = []
}

# CUSTOM SCHEMA ROLES
# Define new database roles per database with fine-grained schema-object grants.
# These roles are not granted to any users by default; wire them to business roles only if desired.
# YAML example:
# custom_schema_roles:
#   gold:
#     restricted_all:
#       name: "ROLE_GOLD_${var.snowflake_env}_RESTRICTED_ALL"   # optional; default generated if omitted
#       comment: "Role with broad schema-object privileges, not assigned by default"
#       grants:
#         - { object_type: "*", scope: all, all_privileges: true }
#         - { object_type: "TABLES", schema: "REPORTING", scope: all, privileges: ["SELECT"] }
variable "custom_schema_roles" {
  description = "Per-database custom roles with explicit schema-object grants"
  type = map(map(object({
    name    = optional(string)
    comment = optional(string)
    grants = optional(list(object({
      object_type    = string                  # e.g. "TABLES", "VIEWS", or "*"
      scope          = optional(string, "all") # "all" or "future"
      schema         = optional(string)        # if set, grant in this schema only
      all_privileges = optional(bool)          # true => all schemaObjectPrivileges
      privileges     = optional(list(string))  # explicit privileges
    })), [])
  })))
  default = {}
}

# SERVICE USERS
# How to extend (via Terragrunt YAML inputs):
# service_users:
#   dbt:
#     name_prefix: "DBT_SERVICE_USER"          # final name becomes <name_prefix>_<ENV>
#     default_role_key: "transform"            # references var.technical_roles key
#     default_warehouse_key: "transform"       # references var.warehouses key
#     default_database_key: "silver"           # references var.databases key (namespace)
#     default_secondary_roles_option: "ALL"
#     technical_role_keys: ["transform"]       # which technical roles to grant to this user
#     email: "dbt@example.com"
#     login_name: "dbt@example.com"
#     display_name: "DBT"
variable "service_users" {
  description = "Service users to create and their defaults/grants"
  type = map(object({
    name_prefix                    = string
    default_role_key               = optional(string)
    default_warehouse_key          = optional(string)
    default_database_key           = optional(string)
    default_secondary_roles_option = optional(string, "ALL")
    technical_role_keys            = optional(list(string), [])
    email                          = optional(string)
    login_name                     = optional(string)
    display_name                   = optional(string)
    disabled                       = optional(bool, false)
  }))
  default = {}
}

# Provide public or private keys per service user key (same key as in service_users map).
# Best practice: source from environment/TF Cloud variables in Terragrunt, not committed to VCS.
variable "service_user_public_keys" {
  description = "Map of service user key => RSA public key PEM"
  type        = map(string)
  default     = {}
}

variable "service_user_private_keys" {
  description = "Map of service user key => private key PEM to derive public key"
  type        = map(string)
  default     = {}
}

# TECHNICAL ROLE → USER GRANTS
# How to extend (via Terragrunt YAML inputs):
# tech_role_user_grants:
#   DBT_USER: ["transform"]            # grant TECHNICAL_ACCOUNT_ROLE_TRANSFORM_<ENV> to DBT_USER
#   ANALYST_1: ["reporting"]
#   ETL_BOT: ["ingestion", "transform"]
variable "tech_role_user_grants" {
  description = "Map of user_name => list of technical role keys to grant"
  type        = map(list(string))
  default     = {}
}

# BUSINESS ROLE → USER GRANTS
# Example (Terragrunt YAML):
# business_role_user_grants:
#   BUSINESS_USER_ANALYTICS_ENGINEER: ["analytics_engineer"]
#   BUSINESS_USER_DATA_ENGINEER: ["data_engineer"]
variable "business_role_user_grants" {
  description = "Map of user_name => list of business role keys to grant"
  type        = map(list(string))
  default     = {}
}
