SHELL:=/bin/bash
.DEFAULT_GOAL := help
get_basename = $(notdir $(abspath $(addsuffix $(1),$(dir $(lastword $(MAKEFILE_LIST))))))

EXECUTABLES = kubectl terraform terragrunt tfenv tgenv aws
K := $(foreach cmd,$(EXECUTABLES),\
        $(if $(shell which $(cmd)),,$(error "$(cmd) not found in PATH, Please install $(cmd)")))


TG_RUN_ALL_OPTIONS := \
		--terragrunt-include-dir technical-test-env/vpc \
		--terragrunt-include-dir technical-test-env/eks \
		--terragrunt-include-dir technical-test-env/cert-manager \
		--terragrunt-include-dir technical-test-env/cluster-autoscaler \
		--terragrunt-include-dir technical-test-env/ecr/ecr-backend-nodejs \
		--terragrunt-include-dir technical-test-env/ecr/ecr-frontend-react

plan:
	@terragrunt run-all plan $(TG_RUN_ALL_OPTIONS)
apply:
	@terragrunt run-all apply $(TG_RUN_ALL_OPTIONS)
destroy:
	@terragrunt run-all destroy $(TG_RUN_ALL_OPTIONS)
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%30s\033[0m : %s\n", $$1, $$2}' $(MAKEFILE_LIST)

