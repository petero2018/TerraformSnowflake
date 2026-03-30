#!/usr/bin/env bash
# Migrates snowflake_user.service_users → snowflake_service_user.service_users
# in the Terraform remote state for a given 08-service-users stack.
#
# Usage:
#   eval $(make load-env TF_ENV=dev)   # or prod
#   bash scripts/migrate-service-users-state.sh dev
#   bash scripts/migrate-service-users-state.sh prod
#
# What it does:
#   1. Pulls remote state JSON
#   2. Rewrites every "snowflake_user" resource whose module address contains
#      "service_users" → "snowflake_service_user" (type field + address strings)
#   3. Pushes the edited state back with a serial bump
#   4. Cleans up the temp file
#
# Dry-run (no push): pass --dry-run as second argument.

set -euo pipefail

ENV="${1:-dev}"
DRY_RUN="${2:-}"
STACK_DIR="$(git rev-parse --show-toplevel)/terragrunt/${ENV}/eu-west-2/08-service-users"
TMP="$(mktemp /tmp/tf-state-XXXXXX.json)"
EDITED="$(mktemp /tmp/tf-state-edited-XXXXXX.json)"

cleanup() { rm -f "$TMP" "$EDITED"; }
trap cleanup EXIT

echo "==> Stack: ${STACK_DIR}"
echo "==> Pulling remote state..."
(cd "$STACK_DIR" && terragrunt state pull) > "$TMP"

# Verify the state actually contains the old resource type
if ! grep -q '"type": *"snowflake_user"' "$TMP"; then
  echo "==> No snowflake_user resources found in state — nothing to migrate."
  exit 0
fi

echo "==> Resources to migrate:"
python3 -c "
import json, sys
state = json.load(open('$TMP'))
for r in state.get('resources', []):
    if r.get('type') == 'snowflake_user' and r.get('name') == 'service_users':
        for inst in r.get('instances', []):
            key = inst.get('index_key', '?')
            print(f'  snowflake_user.service_users[\"{key}\"] → snowflake_service_user.service_users[\"{key}\"]')
"

echo ""
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo "==> DRY RUN — no changes pushed."
  exit 0
fi

read -r -p "Proceed with state edit and push? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

echo "==> Editing state JSON..."
python3 - "$TMP" "$EDITED" <<'PYEOF'
import json, sys

src, dst = sys.argv[1], sys.argv[2]
state = json.load(open(src))

# Attributes that exist on snowflake_user but NOT on snowflake_service_user
ATTRS_TO_REMOVE = {
    "must_change_password",
    "disable_mfa",
    "password",
    "mins_to_bypass_mfa",
    "mins_to_unlock",
    "network_policy",
    "snowflake_support",
}

for r in state.get('resources', []):
    if r.get('type') == 'snowflake_user' and r.get('name') == 'service_users':
        r['type'] = 'snowflake_service_user'
        for inst in r.get('instances', []):
            # snowflake_service_user schema_version is 0; snowflake_user was 1
            inst['schema_version'] = 0
            attrs = inst.get('attributes', {})
            for attr in ATTRS_TO_REMOVE:
                attrs.pop(attr, None)

# Bump serial so Terraform accepts the push
state['serial'] = state.get('serial', 0) + 1

with open(dst, 'w') as f:
    json.dump(state, f, indent=2)

print(f"  Done. New serial: {state['serial']}")
PYEOF

echo "==> Pushing edited state..."
(cd "$STACK_DIR" && terragrunt state push "$EDITED")

echo ""
echo "==> Migration complete for ${ENV}."
echo "    Run: cd ${STACK_DIR} && terragrunt plan"
echo "    Expect only in-place updates (query_tag), no destroy/create."
