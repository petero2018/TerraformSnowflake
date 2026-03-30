#!/usr/bin/env bash
# Migrates the 04-database-roles Terraform state after the database_role module refactor.
#
# What changed:
#   - db_all + db_usage          → db_privileges       (new resource name)
#   - schema_all_privs + schema_future_all_privs → schema_privileges / schema_future_privileges
#   - object_all_privs / object_privileges       → same name, but different for_each keys
#   - custom_roles (separate resource)           → merged into db_roles / db_roles_prod
#   - custom_all_db / custom_all_schema / custom_privs_db / custom_privs_schema → gone
#
# Strategy: remove ALL grant resources and the custom_roles resource from state.
# The role objects themselves (db_roles, db_roles_prod) stay — they are not recreated.
# Terraform will re-import / re-create the grants on the next apply (idempotent in Snowflake).
#
# Usage:
#   eval $(bash scripts/load-env.sh dev)
#   bash scripts/migrate-db-roles-state.sh dev
#   bash scripts/migrate-db-roles-state.sh prod

set -euo pipefail

ENV="${1:-dev}"
STACK_DIR="$(dirname "$0")/../terragrunt/${ENV}/eu-west-2/04-database-roles"

echo "==> Listing current state in ${STACK_DIR}..."
cd "${STACK_DIR}"

# Capture state list
RESOURCES=$(terragrunt state list 2>/dev/null)

# Resource name patterns to remove (old names + new names with stale keys)
PATTERNS=(
  "snowflake_grant_privileges_to_database_role.db_all"
  "snowflake_grant_privileges_to_database_role.db_usage"
  "snowflake_grant_privileges_to_database_role.schema_all_privs"
  "snowflake_grant_privileges_to_database_role.schema_future_all_privs"
  "snowflake_grant_privileges_to_database_role.schema_privileges"
  "snowflake_grant_privileges_to_database_role.schema_future_privileges"
  "snowflake_grant_privileges_to_database_role.object_all_privs"
  "snowflake_grant_privileges_to_database_role.object_privileges"
  "snowflake_grant_privileges_to_database_role.custom_all_db"
  "snowflake_grant_privileges_to_database_role.custom_all_schema"
  "snowflake_grant_privileges_to_database_role.custom_privs_db"
  "snowflake_grant_privileges_to_database_role.custom_privs_schema"
  "snowflake_grant_privileges_to_database_role.db_privileges"
  "snowflake_database_role.custom_roles"
  "snowflake_grant_database_role.to_super_admins"
)

REMOVED=0
for pattern in "${PATTERNS[@]}"; do
  # Find all state entries matching this pattern (handles for_each bracketed keys)
  matches=$(echo "${RESOURCES}" | grep "^${pattern}" || true)
  if [[ -n "${matches}" ]]; then
    while IFS= read -r resource; do
      echo "  Removing: ${resource}"
      terragrunt state rm "${resource}"
      REMOVED=$((REMOVED + 1))
    done <<< "${matches}"
  fi
done

echo ""
echo "==> Done. Removed ${REMOVED} state entries."
echo "==> Run 'terragrunt apply' to re-create grants with the new structure."
