#!/usr/bin/env bash
# Prints `export KEY=VALUE` lines suitable for eval.
# Usage:
#   eval $(make load-env)                            # via Makefile (uses defaults)
#   eval $(bash scripts/load-env.sh dev)
#   eval $(bash scripts/load-env.sh prod)
#
# Arguments:
#   $1 - environment: dev|prod (default: dev)
#
# Private key file paths are read from .env:
#   SNOWFLAKE_PRIVATE_KEY_PATH_DEV  → path to dev  PKCS8 PEM file (may be CRLF)
#   SNOWFLAKE_PRIVATE_KEY_PATH_PROD → path to prod PKCS8 PEM file (may be CRLF)
# The file contents are read and exported as SNOWFLAKE_PRIVATE_KEY.

TF_ENV="${1:-dev}"
ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: env file '$ENV_FILE' not found." >&2
  exit 1
fi

# Export all vars from .env in the root directory
grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | while IFS= read -r line; do
  echo "export $line"
done

echo "export TF_ENV='${TF_ENV}'"

# Derive SNOWFLAKE_USER from env-specific variable
if [[ "$TF_ENV" == "prod" ]]; then
  SF_USER="$(grep -E '^SNOWFLAKE_USER_PROD=' "$ENV_FILE" | cut -d'=' -f2-)"
else
  SF_USER="$(grep -E '^SNOWFLAKE_USER_DEV=' "$ENV_FILE" | cut -d'=' -f2-)"
fi
if [[ -n "$SF_USER" ]]; then
  echo "export SNOWFLAKE_USER='${SF_USER}'"
else
  echo "Warning: SNOWFLAKE_USER_${TF_ENV^^} not found in $ENV_FILE — SNOWFLAKE_USER not set." >&2
fi

if [[ "$TF_ENV" == "prod" ]]; then
  KEY_FILE="${SNOWFLAKE_PRIVATE_KEY_PATH_PROD:-${HOME}/.ssh/kingm_sfprod_tf_key.p8}"
else
  KEY_FILE="${SNOWFLAKE_PRIVATE_KEY_PATH_DEV:-${HOME}/.ssh/kingm_sfdev_tf_key.p8}"
fi

if [[ -f "$KEY_FILE" ]]; then
  KEY_VALUE="$(tr -d '\r' < "$KEY_FILE")"
  printf "export SNOWFLAKE_PRIVATE_KEY=%s\n" "$(printf '%q' "$KEY_VALUE")"
else
  echo "Warning: private key file '$KEY_FILE' not found — SNOWFLAKE_PRIVATE_KEY not set." >&2
fi

# Warn if Terraform Cloud token is missing
if ! grep -q 'TF_TOKEN_app_terraform_io' "$ENV_FILE" 2>/dev/null; then
  echo "Warning: TF_TOKEN_app_terraform_io not found in $ENV_FILE — terraform init will fail. See .env.sample." >&2
fi
