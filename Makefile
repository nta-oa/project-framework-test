# ======================================================================================== #
#                   ___  ___   ___ _____   __  __      _        __ _ _
#                  | _ \/ _ \ / _ \_   _| |  \/  |__ _| |_____ / _(_) |___
#                  |   / (_) | (_) || |   | |\/| / _` | / / -_)  _| | / -_)
#                  |_|_\\___/ \___/ |_|   |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #
# -- < Global configuration > --
# ======================================================================================== #
SHELL := /bin/bash

.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL     := help
CURRENT_MAKEFILE  := $(lastword $(MAKEFILE_LIST))
CURRENT_LOCATION  := $(dir $(abspath $(CURRENT_MAKEFILE)))
ROOT_DIR          := $(CURRENT_LOCATION:%/=%)


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk

# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# ---------------------------------------------------------------------------------------- #
.PHONY: help all clean


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help              Displays the current message
init              Runs the all target in setup/init/Makefile
cicd              Runs the all target in setup/cicd/Makefile
all               Runs the all target on every module of the modules subdirectory
test              Runs the application by launching unit tests
validate          Lint, format and typecheck source code
build             Builds the application by producing artefacts (archives, docker images, etc.)
clean             Cleans the generated intermediary files
iac-init          Initializes the terraform infrastructure
iac-prepare       Prepares the terraform infrastructure by create the variable files
iac-plan          Produces the terraform plan to visualize what will be changed in the infrastructure
iac-deploy        Proceeds to the application of the terraform infrastructure
iac-clean         Cleans the intermediary terraform files to restart the process
deploy            Pushes the application artefact and deploys it by applying the terraform
reinit            Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "-- Welcome to the root makefile help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# < init >
# ---------------------------------------------------------------------------------------- #
# -- this target will perform the complete init of a GCP project
.PHONY: init
init:
	@ENV=$(ENV) $(MAKE) -C setup/init -$(MAKEFLAGS) all


# ---------------------------------------------------------------------------------------- #
# < cicd >
# ---------------------------------------------------------------------------------------- #
# -- this target will perform the cicd setup of a GCP project
.PHONY: cicd
cicd:
	@ENV=$(ENV) $(MAKE) -C setup/cicd -$(MAKEFLAGS) all


# ---------------------------------------------------------------------------------------- #
# This target will perform a complete installation of the current repository.
# ---------------------------------------------------------------------------------------- #
.PHONY: all


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the cleaning of the current parent
clean: iac-clean custom-clean


# -- this target will trigger the cleaning of the git repository, thus all untracked files
# will be deleted, so beware.
.PHONY: reinit
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = iac/.terraform/terraform.tfstate
TF_VARS  = iac/terraform.tfvars
TF_PLAN  = iac/tfplan
TF_STATE = $(wildcard iac/*.tfstate iac/.terraform/*.tfstate)
TF_FILES = $(wildcard iac/*.tf)


# -- internal definition for easing changes
define HERE_TF_VARS
app_name          = "$(APP_NAME)"
env_file          = "$(ENV_FILE)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
project_data      = "$(PROJECT_DATA)"
endef
export HERE_TF_VARS


# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@if [ ! -d iac ]; then \
		echo "[iac-init] :: no infrastructure"; \
	else \
		cd iac; \
		if [ ! -d .terraform ]; then \
			function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
			trap remove_me EXIT; \
			echo "[iac-init] :: initializing terraform"; \
			terraform init \
				-backend-config=bucket=$(DEPLOY_BUCKET) \
				-backend-config=prefix=terraform-state/global \
				-input=false; \
		else \
			echo "[iac-init] :: terraform already initialized"; \
		fi; \
	fi;

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@if [ -d iac ]; then \
		echo "[iac-prepare] :: generation of $(TF_VARS) file"; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		echo "[iac-prepare] :: generation of $(TF_VARS) file DONE."; \
	else \
		echo "[iac-prepare] :: no infrastructure"; \
	fi;

# -- this target will create the iac/tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f iac/tfplan

iac-plan: $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@set -euo pipefail; \
	if [ -d iac ]; then \
		echo "[iac-plan] :: planning the iac in $(PROJECT) ($(PROJECT_ENV))"; \
		cd iac && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN)); \
		echo "[iac-plan] :: planning the iac for $(APP_NAME) DONE."; \
	else \
		echo "[iac-plan] :: no infrastructure"; \
	fi;


# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: launching the parent iac target on $(APP_NAME)"
	@if [ -d iac ]; then \
		cd iac; \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN)); \
	else \
		echo "[$@] :: no infrastructure"; \
	fi;
	@echo "[$@] :: is finished on $(APP_NAME)"

# -- this target will clean the intermediary iac files
# might need to delete the iac/.terraform/terraform.tfstate file
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning Iac intermediary files : '$(TF_PLAN), $(TF_VARS)'"
	@if [ -d iac ]; then \
		rm -fr $(TF_PLAN) $(TF_VARS) iac/.terraform; \
	fi;
	@echo "[$@] :: cleaning Iac intermediary files DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Application > --
# ---------------------------------------------------------------------------------------- #
#
# ---------------------------------------------------------------------------------------- #
# -- < Installing > --
# ---------------------------------------------------------------------------------------- #
# -- this target will install npm dependencies
.PHONY: install
install:
	@echo "[$@] :: installing npm dependencies ..."
	@npm ci
	@echo "[$@] :: installing dependencies is DONE."

# ---------------------------------------------------------------------------------------- #
# -- < Validating > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger lint, format and typecheck
.PHONY: validate
validate:
	@echo "[$@] :: validating source code ..."
	@npm run validate
	@echo "[$@] :: validating source code is DONE."

# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger test
.PHONY: test
test:
	@echo "[$@] :: testing application ..."
	@echo "run test"
	@echo "[$@] :: testing application is DONE."

# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #

# -- this target will trigger build
.PHONY: build
build:
	@echo "[$@] :: building the Web application ..."
	@set -euo pipefail; \
	cp ~/.config/gcloud/application_default_credentials.json cred.json
	npm run build; \
	docker build \
		--platform linux/amd64 \
		--tag gcr.io/$(PROJECT)/$(APP_NAME):latest \
		.;
	@echo "[$@] :: web application build is DONE."

# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
#
# Targets are used to perform the deployment.
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger the deployment on GCR
.PHONY: deploy
deploy:
	@echo "[$@] :: deploying docker image to gcp registry ..."
	@docker push gcr.io/$(PROJECT)/$(APP_NAME):latest;
	@echo "[$@] :: server application deployment is DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Include Custom makefile > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/custom.mk
