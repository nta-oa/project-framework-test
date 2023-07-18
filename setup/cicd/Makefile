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

# enforce ENV value if it does not belong to CICD_ENV_LIST
CICD_ENV_LIST := cicd ops-cicd

ifeq ($(filter $(ENV),$(CICD_ENV_LIST)),)
ENV           := cicd
endif

include $(ROOT_DIR)/includes/pre-requisites.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PROJECT              := $(shell jq -r '.project' $(ENV_FILE))
PROJECT_ENV          := $(shell jq -r '.project_env // "pd"' $(ENV_FILE))
REPOSITORY_NAME      := $(shell jq -r --arg value $(APP_NAME) '.repository_name // $$value' $(ENV_FILE))

# -- bucket definitions
DEPLOY_BUCKET         := $(shell jq -r '.deploy_bucket' $(ENV_FILE))

# Files to protect
PROTECTED_FILES := Makefile module.mk custom.mk \
		includes/*.mk \
		environments/cicd.json environments/ops-cicd.json

# compute the list of protected files that are present
REAL_PROTECTED_FILES     := $(addprefix $(ROOT_DIR)/, $(PROTECTED_FILES))
EXISTING_PROTECTED_FILES := $(wildcard $(REAL_PROTECTED_FILES))
USABLE_PROTECTED_FILES   := $(EXISTING_PROTECTED_FILES:$(ROOT_DIR)/%=%)


# -- compute module variables
MODULES_DIR     := $(filter %/, $(wildcard ../../modules/*/))
MODULES         := $(filter-out %.sample, $(sort $(MODULES_DIR:../../modules/%/=%)))


# -- display environment variables
$(info $(shell printf "=%.s" $$(seq 100)))
$(info -- $(CURRENT_MAKEFILE): Environment variables)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info ENV                  = $(ENV))
$(info ENV_FILE             = $(ENV_FILE))
$(info APP_NAME             = $(APP_NAME))
$(info APP_NAME_SHORT       = $(APP_NAME_SHORT))
$(info PROJECT              = $(PROJECT))
$(info PROJECT_ENV          = $(PROJECT_ENV))
$(info DEPLOY_BUCKET        = $(DEPLOY_BUCKET))
$(info REPOSITORY_NAME      = $(REPOSITORY_NAME))
$(info MODULES              = $(MODULES))
$(info PROTECTED_FILES      = $(USABLE_PROTECTED_FILES))

$(info $(shell printf "=%.s" $$(seq 100)))


# ---------------------------------------------------------------------------------------- #
# -- < Help > --
# ---------------------------------------------------------------------------------------- #
# -- targets that must always be run
.PHONY: help all clean deploy

# -- this target is run whenever Makefile is called without any target. To display help
define HERE_HELP :=
The available targets are:
--------------------------
help            Displays the current message
all             Deploy the infrastructure from scracth
                > create-bucket iac-plan-clean iac-deploy
clean           Clean the generated intermediary files
deploy          Deploy the infrastructure

create-bucket   Creates the CI/CD deploy bucket to store the infrastructure states for all projects
endef
export HERE_HELP

help::
	@echo "-- Welcome to the cicd setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < Main Targets > --
# ---------------------------------------------------------------------------------------- #
all: create-bucket iac-plan-clean iac-deploy

clean: iac-clean
deploy: iac-deploy


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
define HERE_TF_VARS
app_name        = "$(APP_NAME)"
deploy_bucket   = "$(DEPLOY_BUCKET)"
env_file        = "$(ENV_FILE)"
modules         = "$(MODULES)"
protected_files = "$(USABLE_PROTECTED_FILES)"
endef
export HERE_TF_VARS

TF_DIR    := .
TF_MODULE := cicd

# -- includes the terraform makefile after declaring tf vars
include $(ROOT_DIR)/includes/targets/terraform.mk


# ---------------------------------------------------------------------------------------- #
# -- < CI/CD deploy bucket initialization > --
# ---------------------------------------------------------------------------------------- #
# -- This target creates the the CI/CD deploy bucket for all projects
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating CI/CD deploy bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null \
		|| ( \
			gsutil mb -b on -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET); \
			gsutil versioning set on gs://$(DEPLOY_BUCKET); \
		)
