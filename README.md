# TerraformSnowflake

## set env vars

```
export SNOWFLAKE_PRIVATE_KEY=$(cat ~/.ssh/<your_sf_ssh_private_key_here>.p8)

set -a  
source /path/to/your/.env 

printenv | grep ^SNOWFLAKE_

```

From the repo root: `cd terragrunt`
All envs, all stacks:
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