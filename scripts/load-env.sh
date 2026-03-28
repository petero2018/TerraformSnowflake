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
# Private key files (PKCS8 PEM, may be CRLF):
#   dev  → ~/.ssh/kingm_sfdev_tf_key.p8
#   prod → ~/.ssh/kingm_sfprod_tf_key.p8

TF_ENV="${1:-dev}"
ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: env file '$ENV_FILE' not found." >&2
  exit 1
fi

# Export all vars from .env
grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | while IFS= read -r line; do
  echo "export $line"
done

# Export TF_ENV
echo "export TF_ENV='${TF_ENV}'"

# Load the private key for the selected environment, stripping \r (CRLF -> LF)
if [[ "$TF_ENV" == "prod" ]]; then
  KEY_FILE="${HOME}/.ssh/kingm_sfprod_tf_key.p8"
else
  KEY_FILE="${HOME}/.ssh/kingm_sfdev_tf_key.p8"
fi

if [[ -f "$KEY_FILE" ]]; then
  # Read key, strip \r, then single-quote-escape for safe eval
  KEY_VALUE="$(tr -d '\r' < "$KEY_FILE")"
  # Use printf %q to produce a shell-safe quoted string
  printf "export SNOWFLAKE_PRIVATE_KEY=%s\n" "$(printf '%q' "$KEY_VALUE")"
else
  echo "Warning: private key file '$KEY_FILE' not found — SNOWFLAKE_PRIVATE_KEY not set." >&2
fi
