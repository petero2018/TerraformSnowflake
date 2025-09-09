// Grant database roles (ROLE_*_R/RW) to business account roles per configuration.
locals {
  // Only grant database roles explicitly listed in business_roles[*].db_role_grants.
  // If a business role has an empty or missing list, it receives no database role grants.
  business_db_role_grants = {
    for g in flatten([
      for br_key, br in var.business_roles : [
        for grant in try(br.db_role_grants, []) : {
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
