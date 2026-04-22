#!/usr/bin/env bash
# Initializes every Terragrunt stack individually (account + env-specific).
# run-all init cannot be used with a TFC remote backend when workspaces have
# no state yet, because Terragrunt calls `terraform output -json` after each
# init to cache outputs for downstream modules – TFC returns 404 for empty
# workspaces, causing cascading failures.
# Running each stack independently avoids this: each module resolves its own
# dependency blocks, falls back to mock_outputs when the upstream has no state,
# and the init itself always succeeds.
set -euo pipefail

REPO_ROOT="/repo"
TF_ENV="${TF_ENV:-dev}"
REGION="${REGION:-eu-west-2}"

echo "=== Initializing all stacks: env=${TF_ENV}, region=${REGION} ==="
echo ""

FAILED=()

for d in $(find \
    "${REPO_ROOT}/terragrunt/account" \
    "${REPO_ROOT}/terragrunt/${TF_ENV}/${REGION}" \
    -mindepth 1 -maxdepth 1 -type d | sort); do
  [ -f "${d}/terragrunt.hcl" ] || continue
  echo "──────────────────────────────────────────"
  echo "  ${d}"
  echo "──────────────────────────────────────────"
  if (cd "${d}" && terragrunt init --terragrunt-non-interactive); then
    echo "  ✓ OK"
  else
    echo "  ✗ FAILED"
    FAILED+=("${d}")
  fi
  echo ""
done

echo "=========================================="
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "  All stacks initialized successfully."
else
  echo "  The following stacks failed to initialize:"
  for f in "${FAILED[@]}"; do echo "    - ${f}"; done
  exit 1
fi
