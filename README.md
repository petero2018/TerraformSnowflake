# TerraformSnowflake

export SNOWFLAKE_PRIVATE_KEY=$(cat ~/.ssh/<your_sf_ssh_private_key_here>.p8)

set -a  
source /path/to/your/.env 

printenv | grep ^SNOWFLAKE_