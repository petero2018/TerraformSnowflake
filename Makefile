.PHONY: load-env help

TF_ENV ?= dev

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

load-env: ## Export .env + TF_ENV into your shell (run: eval $(make load-env))
	@bash scripts/load-env.sh $(TF_ENV)
