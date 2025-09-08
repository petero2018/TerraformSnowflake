variable "snowflake_env" {
  type        = string
  description = "ENV in caps. Allowed: DEV, PROD"
  validation {
    condition     = contains(["DEV", "PROD"], var.snowflake_env)
    error_message = "snowflake_env must be DEV or PROD"
  }
}

variable "technical_roles" {
  description = "Technical account roles, parent system role, and database-role grants"
  type = map(object({
    parent_role     = optional(string, "SYSADMIN")
    db_role_grants  = optional(list(object({ db = string, kind = string })), [])
  }))

  # Defaults mirror current explicit configuration
  default = {
    transform = {
      parent_role = "SYSADMIN"
      db_role_grants = [
        { db = "operations", kind = "RW" },
        { db = "operations", kind = "R" },
        { db = "bronze",     kind = "RW" },
        { db = "bronze",     kind = "R" },
        { db = "silver",     kind = "RW" },
        { db = "silver",     kind = "R" },
        { db = "gold",       kind = "RW" },
        { db = "gold",       kind = "R" },
      ]
    }
    ingestion = {
      parent_role = "SYSADMIN"
      db_role_grants = [
        { db = "bronze", kind = "RW" },
        { db = "bronze", kind = "R" },
      ]
    }
    reporting = {
      parent_role = "SYSADMIN"
      db_role_grants = [
        { db = "gold", kind = "R" },
      ]
    }
    retl = {
      parent_role = "SYSADMIN"
      db_role_grants = [
        { db = "gold", kind = "R" },
      ]
    }
  }
}

variable "databases" {
  description = "Databases and role flavors per layer"
  type = map(object({
    comment = string
    roles   = list(string) # e.g. ["R", "RW"]
  }))

  # Defaults chosen to match current explicit resources
  default = {
    bronze = {
      comment = "The Bronze Layer is where we land all the data from external source systems. The table structures in this layer correspond to the source system table structures 'as-is,' along with any additional metadata columns that capture the load date/time, process ID, etc."
      roles   = ["R", "RW"]
    }
    silver = {
      comment = "The Silver layer is where we apply standardisation to our source datasets. This standardisation aligns field names across sources, applies common data cleaning operations and organises the data into a well known structure."
      roles   = ["R", "RW"]
    }
    gold = {
      comment = "The Gold layer is for reporting and uses more de-normalized and read-optimized data models with fewer joins. The final layer of data transformations and data quality rules are applied here."
      roles   = ["R", "RW"]
    }
    operations = {
      comment = "This database is designed to store dbt operation materialised data."
      roles   = ["R", "RW"]
    }
    retl = {
      comment = "This database is designed to store retl operations produced data."
      roles   = ["R", "RW"]
    }
  }
}

variable "warehouses" {
  description = "Warehouses and which technical roles should get USAGE/MONITOR"
  type = map(object({
    warehouse_size = string
    comment        = string
    grantees       = list(string) # keys: transform, ingestion, reporting, retl
  }))
  # Defaults chosen to match current explicit resources
  default = {
    transform = {
      warehouse_size = "SMALL"
      comment        = "The Transform Warehouse is used by external transformation tools. Unlike ingestion tools, these external tools may not have their own scalable functionality. Therefore, a burstable larger warehouse size might be required as demand increases."
      grantees       = ["transform"]
    }
    ingestion = {
      warehouse_size = "SMALL"
      comment        = "The Ingestion Warehouse is used by external ingestion tools and processes."
      grantees       = ["ingestion"]
    }
    reporting = {
      warehouse_size = "MEDIUM"
      comment        = "The Reporting Warehouse is used by external reporting and analytics tools and processes."
      grantees       = ["reporting"]
    }
    retl = {
      warehouse_size = "SMALL"
      comment        = "The rETL Warehouse is used by external tools and processes for rETL operations."
      grantees       = []
    }
  }
}
