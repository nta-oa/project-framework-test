# ======================================================================================== #
#                    ___ ___ ___ ___    __  __      _        __ _ _
#                   / __|_ _/ __|   \  |  \/  |__ _| |_____ / _(_) |___
#                  | (__ | | (__| |) | | |\/| / _` | / / -_)  _| | / -_)
#                   \___|___\___|___/  |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #
# -- < Global configuration > --
# ======================================================================================== #
SHELL := /bin/bash

.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL     := help
CURRENT_MAKEFILE  := $(lastword $(MAKEFILE_LIST))
CURRENT_LOCATION  := $(dir $(abspath ../../$(CURRENT_MAKEFILE)))
ROOT_DIR          := $(CURRENT_LOCATION:%/=%)

include $(ROOT_DIR)/includes/common-variables.mk

# ---------------------------------------------------------------------------------------- #
# -- < Environment fail fast checks > --
# ---------------------------------------------------------------------------------------- #
# enforced value
ENV             := cicd

# -- load the configuration environment file
ENV_DIR         := $(ROOT_DIR)/environments
ENV_FILE        := $(ENV_DIR)/$(ENV).json

ifeq ($(wildcard $(ENV_FILE)),)
$(error ENV $(ENV): env file not found)
endif


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PROJECT         := $(shell jq -r '.project' $(ENV_DIR)/pd.json)
REPOSITORY_NAME := $(shell jq -r --arg value $(APP_NAME) '.repository_name // $$value' $(ENV_DIR)/pd.json)

# -- bucket definitions
DEPLOY_BUCKET   := $(APP_NAME_SHORT)-gcs-deploycicd-eu-pd

# Files to protect
PROTECTED_FILES := Makefile module.mk custom.mk \
		includes/common-functions.mk \
		includes/common-variables.mk \
		includes/failfast-checks.mk

# compute the list of protected files that are present
REAL_PROTECTED_FILES     := $(addprefix $(ROOT_DIR)/, $(PROTECTED_FILES))
EXISTING_PROTECTED_FILES := $(wildcard $(REAL_PROTECTED_FILES))
USABLE_PROTECTED_FILES   := $(EXISTING_PROTECTED_FILES:$(ROOT_DIR)/%=%)

#
# -- compute module variables
MODULES_DIR      = $(filter %/, $(wildcard $(ROOT_DIR)/modules/back/))
MODULES          = #$(sort $(MODULES_DIR:$(ROOT_DIR)/modules/%/=%))

# -- display environment variables
$(info $(shell printf "=%.s" $$(seq 100)))
$(info -- $(CURRENT_MAKEFILE): Environment variables)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info ENV              = $(ENV))
$(info ENV_FILE         = $(ENV_FILE))
$(info APP_NAME         = $(APP_NAME))
$(info APP_NAME_SHORT   = $(APP_NAME_SHORT))
$(info PROJECT          = $(PROJECT))
$(info PROJECT_ENV      = $(PROJECT_ENV))
$(info REPOSITORY_NAME  = $(REPOSITORY_NAME))
$(info MODULES          = $(MODULES))
$(info PROTECTED_FILES  = $(USABLE_PROTECTED_FILES))
$(info DEPLOY_BUCKET    = $(DEPLOY_BUCKET))

$(info $(shell printf "=%.s" $$(seq 100)))


# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# other targets are locally added to .PHONY
# ---------------------------------------------------------------------------------------- #
.PHONY: help all


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
display-env     Displays the environment variables that will be used
all             Initializes the application (APis enabling, bucket creation, etc.)
create-bucket   Creates the deployment bucket necessary to store infrastructrue states
clean           Cleans all the files created by the setup process
iac-prepare     Prepares the terraform infrastructure by create the variable files
iac-plan        Produces the terraform plan to visualize what will be changed in the
                infrastructure
iac-deploy      Proceeds to the application of the terraform infrastructure
iac-clean       Cleans the intermediary terraform files to restart the process
reinit          Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "-- Welcome to the cicd setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""



# ---------------------------------------------------------------------------------------- #
# This target will perform the complete setup of the current repository.
# ---------------------------------------------------------------------------------------- #
all: create-bucket iac-plan-clean iac-deploy

clean: iac-clean


# -- This target triggers the creation of the necessary buckets
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@echo "[$@] :: bucket creation is over."


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = .terraform/terraform.tfstate
TF_VARS  = terraform.tfvars
TF_PLAN  = tfplan
TF_STATE = $(wildcard *.tfstate .terraform/*.tfstate)
TF_FILES = $(wildcard *.tf) $(wildcard $(ENV_DIR)/*.json)

# -- this target will clean the local terraform infrastructure
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning the infrastructure"
	@rm -fr .terraform $(TF_STATE) $(TF_VARS) $(TF_PLAN)
	@echo "[$@] :: infrastructure cleaning DONE"

# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@set -euo pipefail; \
	if [ ! -d .terraform ]; then \
		function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
		trap remove_me EXIT; \
		echo "[iac-init] :: initializing terraform"; \
		terraform init \
			-backend-config=bucket=$(DEPLOY_BUCKET) \
			-backend-config=prefix=terraform-state/cicd \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
app_name        = "$(APP_NAME)"
deploy_bucket   = "$(DEPLOY_BUCKET)"
env_file        = "$(ENV_FILE)"
modules         = "$(MODULES)"
protected_files = "$(USABLE_PROTECTED_FILES)"
endef
export HERE_TF_VARS

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@echo "[iac-prepare] :: generation of $(TF_VARS) file";
	@echo "$$HERE_TF_VARS" > $(TF_VARS);
	@echo "[iac-prepare] :: generation of $(TF_VARS) file DONE.";

# -- this target will create the tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f tfplan

iac-plan: $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@echo "[iac-plan] :: planning the iac";
	@set -euo pipefail; \
	terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN));
	@echo "[iac-plan] :: planning the iac for $(APP_NAME) DONE.";

# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: $(TF_PLAN)
	@echo "[$@] :: applying the infrastructure for $(APP_NAME)"
	@terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));
	@echo "[$@] :: infrastructure applied on $(APP_NAME)"

# -- this target re-initializes the git working tree removing untracked and ignored files
.PHONY: reinit
reinit:
	@rm -rf .terraform* terraform.tfstate* tfplan
