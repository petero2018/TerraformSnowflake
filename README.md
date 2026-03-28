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
| `SNOWFLAKE_PRIVATE_KEY` | RSA private key PEM for JWT auth |
| `SNOWFLAKE_ACCOUNT_NAME` | Account identifier |
| `SNOWFLAKE_ORGANIZATION_NAME` | Organization name |
| `SNOWFLAKE_USER` | Optional. Snowflake login for Terraform (default `TERRAFORM`). Use distinct users per environment (e.g. `TERRAFORM_DEV` / `TERRAFORM_PROD`) with separate keys in CI for audit and credential isolation. |

```
export SNOWFLAKE_PRIVATE_KEY=$(cat ~/.ssh/<your_sf_ssh_private_key_here>.p8)
export SNOWFLAKE_USER=TERRAFORM   # optional; omit to use TERRAFORM

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