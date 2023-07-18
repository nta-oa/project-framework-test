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

include $(ROOT_DIR)/includes/pre-requisites.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


# ---------------------------------------------------------------------------------------- #
# -- < Help > --
# ---------------------------------------------------------------------------------------- #
# -- targets that must always be run
.PHONY: help all init init-all cicd gcb-cicd \
	clean build deploy $(MODULES)

# -- this target is run whenever Makefile is called without any target. To display help
define HERE_HELP :=
The available targets are:
--------------------------
help              Display the current message
init              Run the all target in setup/init/Makefile
cicd              Run the all target in setup/cicd/Makefile

all               Run the all target on every module of the modules subdirectory
clean             Clean the generated intermediary files
build             Build the application by producing artefacts (archives, docker images, etc.)
deploy            Push the application artefact and deploys it by applying the terraform
endef
export HERE_HELP

help::
	@echo "-- Welcome to the root makefile help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < init > --
# ---------------------------------------------------------------------------------------- #
# -- this target performs the complete init of a GCP project
init:
	@ENV=$(ENV) $(MAKE) -C setup/init -$(MAKEFLAGS) all


init-all:
	sh bin/init-all.sh


# ---------------------------------------------------------------------------------------- #
# < cicd >
# ---------------------------------------------------------------------------------------- #
# -- this target performs the cicd setup of a GCP project
cicd:
	@ENV=cicd $(MAKE) -C setup/cicd -$(MAKEFLAGS) all


# -- internal definition for easing changes
define HERE_CICD :=
steps:
  - id: CICD deploy
    name: gcr.io/itg-btdpshared-gbl-ww-pd/generic-build
    dir: setup/cicd
    entrypoint: make
    args:
      - ENV=cicd
      - all
endef
export HERE_CICD

gcb-cicd:
	tmp_file="cloudbuild-cicd.yaml" \
		&& echo "$$HERE_CICD" > "$${tmp_file}" \
		&& gcloud builds submit \
			--project $(shell cat environments/cicd.json | jq -r '.project') \
			--config "$${tmp_file}" \
		&& rm -f "$${tmp_file}" || rm -f "$${tmp_file}";


# ---------------------------------------------------------------------------------------- #
# -- < Main targets > --
# ---------------------------------------------------------------------------------------- #
# -- this target performs a complete installation of the current repository
all: deploy $(MODULES)

# -- this targets will trigger a given target for all repository
%-all:
	@$(MAKE) -$(MAKEFLAGS) $* $(foreach mod, $(MODULES), $*-module-$(mod))

clean: iac-clean custom-clean
build: # for consistency
deploy: iac-deploy custom-deploy


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
define HERE_TF_VARS :=
app_name          = "$(APP_NAME)"
env_file          = "$(ENV_FILE)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
deploy_bucket     = "$(DEPLOY_BUCKET)"
endef
export HERE_TF_VARS

TF_DIR    := iac
TF_MODULE := global

# -- includes the terraform makefile after declaring tf vars
include $(ROOT_DIR)/includes/targets/terraform.mk



# ---------------------------------------------------------------------------------------- #
# -- < Module targets > --
# ---------------------------------------------------------------------------------------- #
# -- this target triggers the full installation of a given module
$(MODULES):
	@echo "Calling module.mk for $@"
	@$(MAKE) -f ../../module.mk -C modules/$@ -$(MAKEFLAGS) all MODULE_NAME=$@


MODULE_TARGETS = $(foreach module, $(MODULES), $(addsuffix -module-${module}, \
	all help prepare-test test build deploy e2e-test \
	iac-clean iac-plan iac-deploy \
	clean-app build-app local-test \
))

# -- this targets will trigger a supported target for an existing module
$(MODULE_TARGETS):
	@echo "Calling module.mk for $@"
	@ \
		TARGET=$$(echo "$@" | sed -E "s/(.+)-module-(.+)/\1/g"); \
		MODULE=$$(echo "$@" | sed -E "s/(.+)-module-(.+)/\2/g"); \
		$(MAKE) -f ../../module.mk -C modules/$$MODULE -$(MAKEFLAGS) $$TARGET MODULE_NAME=$$MODULE


# ---------------------------------------------------------------------------------------- #
# -- < Custom makefile > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/custom.mk


# ---------------------------------------------------------------------------------------- #
# -- < To run targets in Cloud Build > --
# ---------------------------------------------------------------------------------------- #
# -- cloudbuild authorized targets
GCB_TARGETS       := all help test build deploy sql-deploy iac-plan iac-deploy $(MODULES)
GCB_TEMPLATES_DIR := $(ROOT_DIR)/.gcb/root

# -- includes the gcb makefile after the mandatory variables definition
include $(ROOT_DIR)/includes/targets/cloudbuild.mk


# ---------------------------------------------------------------------------------------- #
# -- < Script to update the framework > --
# ---------------------------------------------------------------------------------------- #
update:
	@$(ROOT_DIR)/bin/update
