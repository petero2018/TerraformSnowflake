# TerraformSnowflake

A Terraform + Terragrunt project that provisions the foundational infrastructure of a **Snowflake-based analytics platform** — supporting multiple personas, environments, and tools from a single YAML-driven configuration.

---

## What this project does

This project provisions the core building blocks of an analytics platform on Snowflake, enabling access for:

| Persona | Examples |
|---|---|
| **Data Engineers** | dbt, Airflow, Fivetran, Kafka, rETL tools |
| **Analytics Engineers** | dbt, SQL-based modelling |
| **Data Scientists** | SQL-based analysis, ML feature access via warehouse |
| **Analysts** | BI tools (Looker, etc.) |
| **Software / Application Engineers** | API consumers, app integrations |
| **Platform Admins** | Terraform service users, monitoring |

### What gets provisioned

| Component | Description |
|---|---|
| **Databases** | Medallion architecture (Bronze → Silver → Gold), Operations, rETL, Admin |
| **Schemas** | Minimal — tools are expected to manage their own schemas |
| **Database Roles** | Per-database `READ` and `READ_WRITE` roles with correct privilege sets; custom roles supported |
| **Account Roles** | `BUSINESS_ACCOUNT_ROLE_*` for human users, `TECHNICAL_ACCOUNT_ROLE_*` for service users |
| **Role Grants** | Database roles granted to account roles; account roles granted to users |
| **Warehouses** | Configurable compute — size, type (single/multi-cluster), generation, auto-suspend |
| **Warehouse Grants** | Warehouse USAGE grants per account role |
| **Service Users** | Keypair-authenticated programmatic users (dbt, Fivetran, Airflow, Looker, etc.) |
| **Human Users** | Okta SSO-managed users created and granted business roles per environment |
| **Network Policies** | IP allowlist/blocklist at account and user level |
| **Resource Monitors** | Credit usage tracking and alerting at account level |

---

## Architecture

### YAML → Terragrunt → Terraform Modules

All configuration lives in YAML files under `terragrunt/common/`. Terragrunt reads these files and feeds them into reusable Terraform modules:

```
terragrunt/common/
  env/          ← per-environment config (databases, roles, warehouses, users, policies)
  global/       ← account-level config (human users, role grants)

modules/snowflake/
  database/           warehouse/          schema/
  database_role/      account_role/       role_grant/
  warehouse_grant/    user/               network_policy/
  resource_monitor/
```

### Environment model

The project assumes **dev and prod run under the same Snowflake account** — with environment suffixes on object names (e.g. `DATABASE_ROLE_SILVER_DEV_RW_DEFAULT`). It can be adapted to separate accounts per environment under a Snowflake organisation.

### Stack execution order

**Apply** (account first, then region stacks):
```
terragrunt/account/      → 10-admin-database → 11-account-database-roles → 20-admin-schemas
                           30-users → 40-network-policies → 50-resource-monitors

terragrunt/<env>/us-west-2/
  01-databases → 02-schemas → 03-warehouses → 04-database-roles
  → 05-account-roles → 06-role-grants → 07-warehouse-grants
  → 08-service-users → 09-svc-user-network-policies
```

**Destroy**: reverse order — region stacks first, account stacks last.

---

## Prerequisites

- [Docker](https://www.docker.com/) — all Terraform/Terragrunt/SOPS tooling runs inside a container
- A Snowflake account (free trial works)
- An [HCP Terraform](https://app.terraform.io/) account (used as the remote backend)
- `make` (standard on macOS/Linux)
- `age` key for SOPS secret encryption (generated via `make sops-keygen`)

---

## Bootstrap

Follow the step-by-step instructions in [`bootstrap/snowflake/terraform_user`](bootstrap/snowflake/terraform_user). It covers:

1. **Keypair generation** — create RSA key(s) for the Terraform service user(s)
2. **Snowflake user creation** — `CREATE USER TERRAFORM_DEV / TERRAFORM_PROD` with the public key
3. **Role grants** — `SYSADMIN`, `SECURITYADMIN`, `ACCOUNTADMIN` to the Terraform user(s)
4. **`.env` file** — copy `.env.sample`, fill in account/org/region/user values
5. **Private keys** — place the PKCS8 PEM keypair files at the expected paths:
   - dev:  `~/.ssh/<your_private_key_file>.p8`
   - prod: `~/.ssh/<your_private_key_file>.p8`

   These are loaded automatically by `scripts/load-env.sh` and exported as `SNOWFLAKE_PRIVATE_KEY`. They are **never** stored in the repository.
6. **SOPS age key** — `make sops-keygen`, add the printed public key to `.sops.yaml`
7. **Docker image** — `make docker-build`

### Environment variables

The `.env` file (gitignored, copied from `.env.sample`) provides:

| Variable | Description |
|---|---|
| `SNOWFLAKE_USER_DEV` | Terraform service user name for dev (default: `TERRAFORM_DEV`) |
| `SNOWFLAKE_USER_PROD` | Terraform service user name for prod (default: `TERRAFORM_PROD`) |
| `SNOWFLAKE_ACCOUNT_NAME` | Snowflake account name (Snowsight → Admin → Accounts) |
| `SNOWFLAKE_ORGANIZATION_NAME` | Snowflake organisation name |
| `SNOWFLAKE_REGION` | Snowflake region (e.g. `us-west-2`) |

The following variable is **not** in `.env` — it is set at runtime by `scripts/load-env.sh`:

| Variable | Source |
|---|---|
| `SNOWFLAKE_PRIVATE_KEY` | Loaded from `~/.ssh/<your_private_key_file>.p8` (dev) or `~/.ssh/<your_private_key_file>.p8` (prod) |

> **No warehouse needed.** The Terraform provider only performs DDL operations (CREATE DATABASE, CREATE ROLE, GRANT, etc.) — these are metadata-only in Snowflake and do not consume compute credits.

---

## Daily usage

### Load environment variables into your shell

```bash
eval $(make load-env TF_ENV=dev)   # dev
eval $(make load-env TF_ENV=prod)  # prod
```

### Run plan / apply for a single stack

```bash
# Via Docker (recommended)
make docker-plan  TF_ENV=dev STACK=01-databases
make docker-apply TF_ENV=dev STACK=01-databases

# Or directly (if tools are installed locally)
cd terragrunt/dev/us-west-2/01-databases
terragrunt plan
terragrunt apply
```

### Run all stacks in an environment

See the [Platform lifecycle](#platform-lifecycle) section below for the full ordered apply and destroy sequences across both dev and prod.

### Manage secrets (SOPS)

```bash
make sops-edit    FILE=secrets/dev.yaml   # edit encrypted secrets
make sops-encrypt FILE=secrets/dev.yaml   # encrypt a plain YAML file
make sops-decrypt FILE=secrets/dev.yaml   # decrypt to stdout
```

---

## Secret management with SOPS

### Overview

Service user authentication relies on **RSA keypair authentication** in Snowflake. Each service user (dbt, Fivetran, Airflow, Looker, Kafka, Growthbook, etc.) has its own keypair. The **public keys** are stored in SOPS-encrypted YAML files inside the repository — this is safe to commit because the content is encrypted at rest.

The private keys **never enter the repository**. They are distributed separately to each service (e.g. stored in a secrets manager, Keeper, or injected as environment variables at runtime).

### How secrets flow into Terraform

```
secrets/dev.yaml  (SOPS-encrypted, committed to git)
secrets/prod.yaml (SOPS-encrypted, committed to git)
        │
        │  sops_decrypt_file() — called at plan/apply time
        │  (requires age private key at ~/.config/sops/age/keys.txt)
        ▼
08-service-users/terragrunt.hcl
  locals {
    secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/dev.yaml"))
  }
  inputs = {
    service_user_public_keys = local.secrets.service_user_public_keys
  }
        │
        ▼
modules/snowflake/user/main.tf
  → snowflake_user.<name> { rsa_public_key = ... }
```

Decryption happens **inside Docker** at `plan`/`apply` time. The age private key is mounted read-only into the container from `~/.config/sops/age/keys.txt`.

### Secret file structure

`secrets/dev.yaml` and `secrets/prod.yaml` both follow this schema (shown plain, before encryption):

```yaml
service_user_public_keys:
  dbt:            "<RSA public key contents — no BEGIN/END headers>"
  dbt_operations: "<RSA public key contents>"
  fivetran:       "<RSA public key contents>"
  kafka:          "<RSA public key contents>"
  airflow:        "<RSA public key contents>"
  looker:         "<RSA public key contents>"
  growthbook:     "<RSA public key contents>"
```

Once encrypted with SOPS, every value becomes an `ENC[AES256_GCM,...]` ciphertext blob. The `sops:` metadata block at the bottom of the file stores the encrypted data key (wrapped with your age public key) — this is what allows decryption with the matching private key.

### Encryption configuration: `.sops.yaml`

The `.sops.yaml` file at the repo root tells SOPS which key to use and which files to encrypt:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1vh9mulxax6vxakhhvlytd3028p3ty546d9dnggfrj6xrq4duw9xqat7aqt
```

Any file matching `secrets/*.yaml` will be encrypted using the listed age public key. **To add a new team member or CI system**, append their age public key to the `age:` list (comma-separated or as a YAML block) and re-encrypt the files.

### Step-by-step: creating secrets for a new environment

**1. Generate RSA keypairs for each service user**

```bash
make sops-generate-service-keys
```

This prints a shell script template. Run it manually (or adapt it) to generate individual 4096-bit RSA keys:

```bash
# Example for one user — repeat for each service:
openssl genrsa 4096 2>/dev/null | \
  openssl pkcs8 -topk8 -nocrypt -inform PEM -outform PEM > ~/.ssh/svc_dbt_dev.p8

# Extract the public key (strip PEM headers — Snowflake expects bare base64):
openssl rsa -in ~/.ssh/svc_dbt_dev.p8 -pubout 2>/dev/null \
  | grep -v "^-----" | tr -d '\n'
```

**2. Create a plain YAML file with the public keys**

```bash
cp secrets/dev.yaml secrets/dev.yaml.bak   # optional backup of previous version
cat > secrets/dev.yaml <<'EOF'
service_user_public_keys:
  dbt:            "MIIBIjANBgkq..."
  dbt_operations: "MIIBIjANBgkq..."
  fivetran:       "MIIBIjANBgkq..."
  kafka:          "MIIBIjANBgkq..."
  airflow:        "MIIBIjANBgkq..."
  looker:         "MIIBIjANBgkq..."
  growthbook:     "MIIBIjANBgkq..."
EOF
```

**3. Encrypt the file with SOPS**

```bash
make sops-encrypt FILE=secrets/dev.yaml
```

The file is now encrypted in-place. It is safe to commit to git.

**4. Verify the encryption**

```bash
make sops-decrypt FILE=secrets/dev.yaml   # prints decrypted YAML to stdout
```

### Editing existing secrets

To rotate a key or add a new service user:

```bash
make sops-edit FILE=secrets/dev.yaml
```

This opens the file decrypted in `vi` inside Docker. Save and exit — SOPS re-encrypts automatically.

### Adding a new service user

1. Generate a keypair (see above).
2. Add the user key to `secrets/dev.yaml` and `secrets/prod.yaml` via `make sops-edit`.
3. Add the user definition to `terragrunt/common/env/service_users.yaml`.
4. Apply `08-service-users` (or run the full apply).

### Rotating the age key (disaster recovery)

If the age private key is lost:

1. Generate a new key: `make sops-keygen`
2. Update `.sops.yaml` with the new public key.
3. Re-encrypt all secrets files:
   ```bash
   make sops-encrypt FILE=secrets/dev.yaml
   make sops-encrypt FILE=secrets/prod.yaml
   ```
4. Securely back up the new private key from `~/.config/sops/age/keys.txt`.

---

## Platform lifecycle

### Full apply — provision everything from scratch

Run these commands in order. Each block must complete successfully before the next.

```bash
# ── 1. Prod account-level resources (databases, roles, human users, policies) ──
eval $(make load-env TF_ENV=prod)
cd terragrunt/account
terragrunt run-all apply -auto-approve --parallelism 1

# ── 2. Prod region resources (schemas, warehouses, role grants, service users) ──
eval $(make load-env TF_ENV=prod)
cd terragrunt/prod/us-west-2
terragrunt run-all apply -auto-approve --parallelism 1
# Repeat for other prod regions if applicable

# ── 3. Dev account-level resources ──
eval $(make load-env TF_ENV=dev)
cd terragrunt/account
terragrunt run-all apply -auto-approve --parallelism 1

# ── 4. Dev region resources ──
eval $(make load-env TF_ENV=dev)
cd terragrunt/dev/us-west-2
terragrunt run-all apply -auto-approve --parallelism 1
# Repeat for other dev regions if applicable
```

> **Why prod first?** The `account/30-users` stack reads outputs from both `prod/05-account-roles` and `dev/05-account-roles` to grant human users the correct roles for each environment. Prod roles must exist before the account stack can reference them.

### Full destroy — tear everything down

Run in **reverse order**: region stacks first, account stacks last.

```bash
# ── 1. Dev region resources (first — depends on account-level outputs) ──
eval $(make load-env TF_ENV=dev)
cd terragrunt/dev/us-west-2
terragrunt run-all destroy -auto-approve --parallelism 1

# ── 2. Dev account-level resources ──
eval $(make load-env TF_ENV=dev)
cd terragrunt/account
terragrunt run-all destroy -auto-approve --parallelism 1

# ── 3. Prod region resources ──
eval $(make load-env TF_ENV=prod)
cd terragrunt/prod/us-west-2
terragrunt run-all destroy -auto-approve --parallelism 1

# ── 4. Prod account-level resources (last — other stacks depend on these) ──
eval $(make load-env TF_ENV=prod)
cd terragrunt/account
terragrunt run-all destroy -auto-approve --parallelism 1
```

> **Note:** `--parallelism 1` is intentional — Snowflake's provider has known race conditions on concurrent grant operations. Increase only if you have confirmed it is safe in your environment.

### Interactive Docker shell

```bash
make docker-shell   # drops you inside the container with repo and age key mounted
```

---

## Configuration reference

All platform configuration is done via YAML files — no Terraform code changes needed for typical changes.

| File | Purpose |
|---|---|
| `terragrunt/common/env/databases.yaml` | Database definitions |
| `terragrunt/common/env/schemas.yaml` | Schema definitions |
| `terragrunt/common/env/warehouses.yaml` | Warehouse config (size, type, grants) |
| `terragrunt/common/env/database_roles.yaml` | Database role profiles and per-db role definitions |
| `terragrunt/common/env/account_roles.yaml` | Business and technical account roles |
| `terragrunt/common/env/service_users.yaml` | Service user definitions |
| `terragrunt/common/env/network_policies.yaml` | Account/user-level network policies |
| `terragrunt/common/env/resource_monitors.yaml` | Credit monitors |
| `terragrunt/common/global/human_users.yaml` | Human (SSO) user definitions with per-env role grants |
| `terragrunt/common/global/role_grants.yaml` | Account-level role grant mappings |
| `secrets/dev.yaml` / `secrets/prod.yaml` | SOPS-encrypted RSA public keys for service users |


## Snowflake infrastructure config (YAML)

Shared defaults live under `terragrunt/common/snowflake-infrastructure/`:

- `00-foundations.yaml` — databases, `database_role_defaults` (R/RW expansion)
- `10-warehouse.yaml` — `warehouses`, `resource_monitors`, `budgets` (placeholders until wired), `warehouse_grants`
- `11-technical-iam.yaml` — `technical_roles` (optional `db_role_grants_profile`), `service_users`, `tech_role_user_grants`
- `12-business-iam.yaml` — `business_roles`, `business_role_user_grants`
- `20-objects.yaml` — schemas, schema privileges, custom schema roles, object types

Access profile names for technical roles are defined in `terragrunt/includes/snowflake-infrastructure-config.hcl` (`access_profiles`).

**Parent roles (SYSADMIN):** For `technical_roles`, `business_roles`, and `database_roles`, omit `super_admin_roles` to grant each new role to **SYSADMIN** (keeps admin hierarchy). Set `super_admin_roles: []` to skip granting to any parent account role. Set `super_admin_roles: ["OTHER_ROLE"]` for explicit parents.

Each env stack merges those files plus `overrides.yaml` in `terragrunt/<env>/us-west-2/infrastructure/`. To override the derived `database_roles` list, set `database_roles` explicitly in `overrides.yaml`.

A placeholder org catalog is in `terragrunt/org/accounts.yaml` (not applied yet).