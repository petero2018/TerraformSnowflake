// Grant database roles (ROLE_*_R/RW) to business account roles per configuration.
locals {
  // If a business role does not specify db_role_grants, default to read-only on all databases
  // by granting ROLE_<DB>_<ENV>_R for every database in local.dbs.
  business_db_role_grants = {
    for g in flatten([
      for br_key, br in var.business_roles : [
        for grant in (length(try(br.db_role_grants, [])) > 0
          ? br.db_role_grants
          : [for db_key, _ in local.dbs : { db = db_key, kind = "R" }]
        ) : {
          id       = "${br_key}|${grant.db}|${upper(grant.kind)}"
          br_key   = br_key
          role_key = "${grant.db}|${upper(grant.kind)}"
        }
      ]
    ]) : g.id => g
  }
}

resource "snowflake_grant_database_role" "db_role_to_business" {
  provider           = snowflake.securityadmin
  for_each           = local.business_db_role_grants
  database_role_name = snowflake_database_role.db_roles[each.value.role_key].fully_qualified_name
  parent_role_name   = snowflake_account_role.business_roles[each.value.br_key].name
}
