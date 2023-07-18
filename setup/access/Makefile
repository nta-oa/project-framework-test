# ======================================================================================== #
#                    _                     __  __      _        __ _ _
#                   /_\  __ __ ___ ______ |  \/  |__ _| |_____ / _(_) |___
#                  / _ \/ _/ _/ -_|_-<_-< | |\/| / _` | / / -_)  _| | / -_)
#                 /_/ \_\__\__\___/__/__/ |_|  |_\__,_|_\_\___|_| |_|_\___|
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

include $(ROOT_DIR)/includes/pre-requisites.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/common-variables.mk


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
                > iac-plan-clean iac-deploy
clean           Clean the generated intermediary files
deploy          Deploy the infrastructure
endef
export HERE_HELP

help::
	@echo "-- Welcome to the access setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < Main Targets > --
# ---------------------------------------------------------------------------------------- #
all: iac-plan-clean iac-deploy

clean: iac-clean
deploy: iac-deploy


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
define HERE_TF_VARS :=
app_name          = "$(APP_NAME)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
env_file          = "$(ENV_FILE)"
endef
export HERE_TF_VARS

TF_DIR    := .
TF_MODULE := access

# -- includes the terraform makefile after declaring tf vars
include $(ROOT_DIR)/includes/targets/terraform.mk
