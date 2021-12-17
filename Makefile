.DEFAULT_GOAL:=help

# set default shell
SHELL=/bin/bash -o pipefail -o errexit

IMG=ghcr.io/bhojpur/platform-eks-guide:latest

# load .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

ifneq ($(IMAGE_PULL_SECRET_FILE),)
	IMAGE_PULL_SECRET=--volume $(shell realpath ${IMAGE_PULL_SECRET_FILE}):/bhojpur/config.json
else
	IMAGE_PULL_SECRET=
endif

build: ## Build docker image containing the required tools for the installation
	@docker build --squash --quiet . -t ${IMG}
	@mkdir -p ${PWD}/logs

DOCKER_RUN_CMD = docker run -it \
	--pull always \
	--env-file ${PWD}/.env \
	--env NODE_ENV=production \
	--volume ${PWD}/.kubeconfig:/bhojpur/.kubeconfig \
	$(IMAGE_PULL_SECRET) \
	--volume ${PWD}/eks-cluster.yaml:/bhojpur/eks-cluster.yaml \
	--volume ${PWD}/logs:/root/.npm/_logs \
	--volume ${PWD}/platform-config.yaml:/bhojpur/platform-config.yaml \
	--volume ${PWD}/cdk-outputs.json:/bhojpur/cdk-outputs.json \
	--volume ${HOME}/.aws:/root/.aws \
	${IMG} $(1)

install: ## Install Bhojpur.NET Platform
	@echo "Starting install process..."
	@touch ${PWD}/.kubeconfig
	@touch ${PWD}/platform-config.yaml
	@touch ${PWD}/cdk-outputs.json
	@$(call DOCKER_RUN_CMD, --install)

uninstall: ## Uninstall Bhojpur.NET Platform
	@echo "Starting uninstall process..."
	@$(call DOCKER_RUN_CMD, --uninstall)

auth: ## Install OAuth providers
	@echo "Installing auth providers..."
	@$(call DOCKER_RUN_CMD, --auth)

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: build install uninstall auth help
