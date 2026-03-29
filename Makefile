.PHONY: load-env help docker-build docker-run docker-shell docker-plan docker-apply sops-encrypt sops-decrypt sops-edit sops-keygen sops-generate-service-keys

TF_ENV  ?= dev
STACK   ?= 01-databases
REGION  ?= eu-west-2
IMAGE   ?= terraformsnowflake

AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

load-env: ## Export .env + TF_ENV into your shell (run: eval $(make load-env))
	@bash scripts/load-env.sh $(TF_ENV)

# ──────────────────────────────────────────────────────────────────────────
# Docker
# ──────────────────────────────────────────────────────────────────────────

docker-build: ## Build the Docker image
	docker build -t $(IMAGE) docker/

docker-shell: ## Interactive shell inside the container (repo + age key mounted)
	docker run -it --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e TF_TOKEN_app_terraform_io=$(TF_TOKEN_app_terraform_io) \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		$(IMAGE)

docker-plan: ## Run terragrunt plan for ENV+STACK inside Docker (e.g. make docker-plan TF_ENV=dev STACK=01-databases)
	docker run -it --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e TF_TOKEN_app_terraform_io=$(TF_TOKEN_app_terraform_io) \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		$(IMAGE) -c "cd terragrunt/$(TF_ENV)/$(REGION)/$(STACK) && terragrunt plan"

docker-apply: ## Run terragrunt apply for ENV+STACK inside Docker (e.g. make docker-apply TF_ENV=dev STACK=01-databases)
	docker run -it --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e TF_TOKEN_app_terraform_io=$(TF_TOKEN_app_terraform_io) \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		$(IMAGE) -c "cd terragrunt/$(TF_ENV)/$(REGION)/$(STACK) && terragrunt apply"

# ──────────────────────────────────────────────────────────────────────────
# SOPS secret management
# ──────────────────────────────────────────────────────────────────────────

sops-keygen: ## Generate a new age key pair inside Docker and save to ~/.config/sops/age/keys.txt
	@mkdir -p $(HOME)/.config/sops/age
	@if [ -f $(AGE_KEY_FILE) ]; then \
		echo "Key already exists at $(AGE_KEY_FILE) — skipping. Delete it first if you want a new one."; \
	else \
		docker run --rm \
			-v $(HOME)/.config/sops/age:/root/.config/sops/age \
			$(IMAGE) -c "age-keygen -o /root/.config/sops/age/keys.txt && echo '' && echo 'Public key (add this to .sops.yaml):' && grep 'public key' /root/.config/sops/age/keys.txt"; \
	fi

sops-generate-service-keys: ## Generate RSA key pairs for all service users and write to secrets/dev.yaml + secrets/prod.yaml (plain — encrypt afterwards!)
	@docker run --rm \
		-v $(PWD):/repo \
		$(IMAGE) -c " \
		cd /repo && \
		for user in dbt dbt_operations fivetran kafka airflow looker growthbook; do \
			echo \"Generating key for $$user...\"; \
			key=\$$(openssl genrsa 4096 2>/dev/null | openssl pkcs8 -topk8 -nocrypt -inform PEM -outform PEM); \
			echo \"  $$user: generated\"; \
		done && \
		echo '' && \
		echo 'Keys generated. Run this script manually and paste keys into secrets/dev.yaml, then: make sops-encrypt FILE=secrets/dev.yaml'"

sops-encrypt: ## Encrypt a plain YAML secrets file inside Docker (e.g. make sops-encrypt FILE=secrets/dev.yaml)
	docker run --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		$(IMAGE) -c "sops --encrypt --in-place /repo/$(FILE)"

sops-decrypt: ## Decrypt a SOPS-encrypted file to stdout inside Docker (e.g. make sops-decrypt FILE=secrets/dev.yaml)
	docker run --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		$(IMAGE) -c "sops --decrypt /repo/$(FILE)"

sops-edit: ## Edit a SOPS-encrypted file in your editor inside Docker (e.g. make sops-edit FILE=secrets/dev.yaml)
	docker run -it --rm \
		-v $(PWD):/repo \
		-v $(AGE_KEY_FILE):/root/.config/sops/age/keys.txt:ro \
		-e SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
		-e EDITOR=vi \
		$(IMAGE) -c "sops /repo/$(FILE)"
