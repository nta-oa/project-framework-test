# ======================================================================================== #
#             __  __         _      _       __  __      _        __ _ _
#            |  \/  |___  __| |_  _| |___  |  \/  |__ _| |_____ / _(_) |___
#            | |\/| / _ \/ _` | || | / -_) | |\/| / _` | / / -_)  _| | / -_)
#            |_|  |_\___/\__,_|\_,_|_\___| |_|  |_\__,_|_\_\___|_| |_|_\___|
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

include $(ROOT_DIR)/includes/pre-requisites.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


# -- compute module variables
MODULE_NAME          ?= $(shell basename $$(pwd))
override MODULE_NAME := $(shell sed -E 's/^([0-9]+[-])?//' <<< "$(MODULE_NAME)")
MODULE_NAME_SHORT    := $(shell sed 's/-//g' <<< "$(MODULE_NAME)")

# fetch after to tolerate using symlinks locally
MODULE_DIR_NAME      := $(shell echo $(MODULES) | tr " " "\n" | grep -E "^([0-9]+[-])?$(MODULE_NAME)$$")
# verify it is the same without whitespace
ifneq ($(shell echo $(MODULE_DIR_NAME) | xargs | tr -d " "),$(MODULE_DIR_NAME))
$(error \
	ERROR: Multiple matching directories for module $(MODULE_NAME): $(MODULE_DIR_NAME) \
)
endif

# default module type is gcr (for Google Cloud Run)
ifeq (,$(wildcard .module_type))
TYPE                 := gcr
else
TYPE                 := $(shell cat .module_type)
endif

SUPPORTED_MODULE_TYPES := $(shell find $(ROOT_DIR)/includes/module_types -type f \
	-maxdepth 1 -name '*.mk' \
	-exec bash -c 'basename {} | sed -E s/\.mk$$//' \; \
)
# verify module type is supported
ifeq ($(filter $(TYPE),$(SUPPORTED_MODULE_TYPES)),)
$(error \
	ERROR: Unsupported module type '$(TYPE)'. It must belong to: $(SUPPORTED_MODULE_TYPES) \
)
endif


# -- display environment variables (always printed)
$(info MODULE_DIR_NAME   = $(MODULE_DIR_NAME))
$(info MODULE_NAME       = $(MODULE_NAME))
$(info MODULE_NAME_SHORT = $(MODULE_NAME_SHORT))
$(info TYPE              = $(TYPE))

$(info $(shell printf "=%.s" $$(seq 100)))


# -- fetch project info
CLOUDRUN_URL_SUFFIX := $(shell \
	gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) \
)


# -- apigee variables
APIS_FILE                := $(ENV_DIR)/apis.json
ifeq ($(wildcard $(APIS_FILE)),)
$(error ERROR: apis.json file not found: $(APIS_FILE))
endif

APIGEE_DEPLOYER_ENDPOINT := $(shell jq -re '.apigeedeployer' $(APIS_FILE))/v1
APIGEE_PAYLOAD           := apigee_deploy_payload.json
APIGEE_RESPONSE_PAYLOAD  := apigee_deploy_response_payload.json
APIGEE_DEPLOY_SA         := $(APP_NAME_SHORT)-sa-cloudbuild-$(PROJECT_ENV)@$(PROJECT).iam.gserviceaccount.com

API_CONF_FILE            := api_conf.json


# ---------------------------------------------------------------------------------------- #
# -- < Help > --
# ---------------------------------------------------------------------------------------- #
# -- targets that must always be run
.PHONY: help all clean build deploy

# -- this target is run whenever Makefile is called without any target. To display help
define HERE_HELP :=
The available targets are:
--------------------------
help              Display the current message
all               Build and deploy the module
                  > clean prepare-test build deploy
clean             Clean the generated intermediary files
                  > clean-test clean-app iac-clean
build             Test and build the application artefact (archive, docker image, etc.)
                  > test hadolint-test build-app
deploy            Push the application artefact and deploy infrastructure with terraform
                  > deploy-app iac-plan-clean iac-deploy
endef
export HERE_HELP

help::
	@echo "-- Welcome to the module makefile help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < Main targets > --
# ---------------------------------------------------------------------------------------- #
all: clean hadolint-test prepare-test build deploy
	@echo "Makefile launched in $(shell basename ${PWD}) for $(MODULE_NAME)"

clean: clean-test clean-app iac-clean
build: test build-app
deploy: deploy-app iac-plan-clean iac-deploy deploy-apigee


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #

# -- terraform variables declaration
define HERE_TF_VARS :=
app_name            = "$(APP_NAME)"
app_name_short      = "$(APP_NAME_SHORT)"
module_name         = "$(MODULE_NAME)"
module_name_short   = "$(MODULE_NAME_SHORT)"
project             = "$(PROJECT)"
project_env         = "$(PROJECT_ENV)"
deploy_bucket       = "$(DEPLOY_BUCKET)"
env_file            = "$(ENV_FILE)"
cloudrun_url_suffix = "$(CLOUDRUN_URL_SUFFIX)"
endef
export HERE_TF_VARS

TF_DIR         := iac
TF_MODULE      := $(MODULE_NAME)
BUILD_REVISION := revision

# -- includes the terraform makefile after declaring tf vars
include $(ROOT_DIR)/includes/targets/terraform.mk


# ---------------------------------------------------------------------------------------- #
# -- < Python tests > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/targets/python.mk


# ---------------------------------------------------------------------------------------- #
# -- < Module build and deploy > --
# ---------------------------------------------------------------------------------------- #
# -- override targets with those for the module type. Verified with SUPPORTED_MODULE_TYPES
include $(ROOT_DIR)/includes/module_types/$(TYPE).mk

help::
	@cat $(ROOT_DIR)/includes/module_types/help.txt
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < To run targets in Cloud Build > --
# ---------------------------------------------------------------------------------------- #
# -- cloudbuild authorized targets
GCB_TARGETS       := all test build deploy iac-plan iac-deploy deploy-apigee e2e-test
GCB_TEMPLATES_DIR := $(ROOT_DIR)/.gcb/module

# -- includes the gcb makefile after the mandatory variables definition
include $(ROOT_DIR)/includes/targets/cloudbuild.mk
