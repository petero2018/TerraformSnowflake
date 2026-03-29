# TerraformSnowflake

## Snowflake infrastructure config (YAML)

Shared defaults live under `terragrunt/common/snowflake-infrastructure/`:

- `00-foundations.yaml` — databases, `database_role_defaults` (R/RW expansion)
- `10-warehouse.yaml` — `warehouses`, `resource_monitors`, `budgets` (placeholders until wired), `warehouse_grants`
- `11-technical-iam.yaml` — `technical_roles` (optional `db_role_grants_profile`), `service_users`, `tech_role_user_grants`
- `12-business-iam.yaml` — `business_roles`, `business_role_user_grants`
- `20-objects.yaml` — schemas, schema privileges, custom schema roles, object types

Access profile names for technical roles are defined in `terragrunt/includes/snowflake-infrastructure-config.hcl` (`access_profiles`).

**Parent roles (SYSADMIN):** For `technical_roles`, `business_roles`, and `database_roles`, omit `super_admin_roles` to grant each new role to **SYSADMIN** (keeps admin hierarchy). Set `super_admin_roles: []` to skip granting to any parent account role. Set `super_admin_roles: ["OTHER_ROLE"]` for explicit parents.

Each env stack merges those files plus `overrides.yaml` in `terragrunt/<env>/eu-west-2/infrastructure/`. To override the derived `database_roles` list, set `database_roles` explicitly in `overrides.yaml`.

A placeholder org catalog is in `terragrunt/org/accounts.yaml` (not applied yet).

## set env vars

Required for Snowflake provider (see [`terragrunt/includes/providers/snowflake.hcl`](terragrunt/includes/providers/snowflake.hcl)):

| Variable | Purpose |
|----------|---------|
| `SNOWFLAKE_ACCOUNT_NAME` | Account identifier |
| `SNOWFLAKE_ORGANIZATION_NAME` | Organization name |
| `SNOWFLAKE_USER_DEV` | Optional. Snowflake login for dev stacks (e.g. `TERRAFORM_DEV`). Takes priority over `SNOWFLAKE_USER`. |
| `SNOWFLAKE_USER_PROD` | Optional. Snowflake login for prod stacks (e.g. `TERRAFORM_PROD`). Takes priority over `SNOWFLAKE_USER`. |
| `SNOWFLAKE_USER` | Fallback Snowflake login (default `TERRAFORM`). Used when no env-specific var is set. |
| `SNOWFLAKE_PRIVATE_KEY_DEV` | Optional. RSA private key PEM for dev stacks. Takes priority over `SNOWFLAKE_PRIVATE_KEY`. |
| `SNOWFLAKE_PRIVATE_KEY_PROD` | Optional. RSA private key PEM for prod stacks. Takes priority over `SNOWFLAKE_PRIVATE_KEY`. |
| `SNOWFLAKE_PRIVATE_KEY` | Fallback RSA private key PEM for JWT auth. Used when no env-specific key is set. |

```
export SNOWFLAKE_USER_DEV=TERRAFORM_DEV
export SNOWFLAKE_PRIVATE_KEY_DEV=$(cat ~/.ssh/terraform_dev.p8)

export SNOWFLAKE_USER_PROD=TERRAFORM_PROD
export SNOWFLAKE_PRIVATE_KEY_PROD=$(cat ~/.ssh/terraform_prod.p8)

# Single-user local fallback (omit the above and use these instead):
# export SNOWFLAKE_USER=TERRAFORM
# export SNOWFLAKE_PRIVATE_KEY=$(cat ~/.ssh/<your_sf_ssh_private_key_here>.p8)

set -a  
source /path/to/your/.env 

printenv | grep ^SNOWFLAKE_

```

#### All envs, all stacks:

From the repo root: `cd terragrunt`

Plan: `terragrunt run-all plan`

Apply: `terragrunt run-all apply`


Only prod: `terragrunt run-all apply --terragrunt-include-dir terragrunt/prod`

Only certain stacks: `terragrunt run-all apply --terragrunt-include-dir 'terragrunt/**/account' --terragrunt-include-dir 'terragrunt/**/infrastructure'`


Ordering note (account → infrastructure)
If infra grants roles to users created by account, ensure ordering. 
`dependencies { paths = ["../account"] }`


Non-interactive CI: add `--terragrunt-non-interactive`

Speed: add `--parallelism 4`

Visualize DAG: `terragrunt graph-dependencies`