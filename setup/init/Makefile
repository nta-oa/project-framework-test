# ======================================================================================== #
#                     ___      _ _     __  __      _        __ _ _
#                    |_ _|_ _ (_) |_  |  \/  |__ _| |_____ / _(_) |___
#                     | || ' \| |  _| | |\/| / _` | / / -_)  _| | / -_)
#                    |___|_||_|_|\__| |_|  |_\__,_|_\_\___|_| |_|_\___|
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
.PHONY: help all clean deploy iac-clean-state create-bucket create-suffix

# -- this target is run whenever Makefile is called without any target. To display help
define HERE_HELP :=
The available targets are:
--------------------------
help            Displays the current message
all             Create the needed resources and deploy the infrastructure from scracth
                > create-bucket iac-plan-clean iac-deploy create-suffix
clean           Clean the generated intermediary files
deploy          Deploy the infrastructure

create-bucket   Creates the deploy bucket to store the infrastructure states for project
create-suffix   Generate and stores the url suffix for Cloud Run in the deploy bucket.
                It is unique to a GCP project
endef
export HERE_HELP

help::
	@echo "-- Welcome to the initialization setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < Main Targets > --
# ---------------------------------------------------------------------------------------- #
all: create-bucket iac-plan-clean iac-deploy create-suffix

clean: iac-clean
deploy: iac-deploy


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
define HERE_TF_VARS :=
app_name       = "$(APP_NAME)"
project        = "$(PROJECT)"
project_env    = "$(PROJECT_ENV)"
access_token   = "$(shell gcloud auth print-access-token --project $(PROJECT))"
region         = "$(REGION)"
env_file       = "$(ENV_FILE)"
endef
export HERE_TF_VARS

TF_DIR    := .
TF_MODULE := init

# -- includes the terraform makefile after declaring tf vars
include $(ROOT_DIR)/includes/targets/terraform.mk

# -- this target cleans the terraform state to prepare safe plan
iac-clean-state::
	@echo "[$@] :: Cleaning the infrastructure state before plan or deploy"

	@echo "[$@] :: Checking if the app engine needs to be imported..."
	@if ! (terraform state list | grep "google_app_engine_application.app" >/dev/null); \
	then \
		if (gcloud app describe --verbosity=none --project=$(PROJECT) >/dev/null); \
		then \
			echo "[$@] :: Import App Engine into state since it's missing..."; \
			terraform import google_app_engine_application.app $(PROJECT); \
		fi; \
	fi;

	@echo "[$@] :: Checking if the GCB log bucket needs to be imported..."
	@if ! (terraform state list | grep "google_storage_bucket.custom_gcb_log_bucket" >/dev/null); \
	then \
		if (gcloud storage buckets list --project=$(PROJECT) | grep "id: cloudbuild-gcs-eu-$(PROJECT)" >/dev/null); \
		then \
			echo "[$@] :: Import GCB log bucket into state since it's missing..."; \
			terraform import google_storage_bucket.custom_gcb_log_bucket $(PROJECT)/cloudbuild-gcs-eu-$(PROJECT); \
		fi; \
	fi;


# ---------------------------------------------------------------------------------------- #
# -- < Deploy bucket initialization > --
# ---------------------------------------------------------------------------------------- #
# -- This target creates the the deploy bucket for project
create-bucket:
	@echo "[$@] :: creating deploy bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null \
		|| ( \
			gsutil mb -b on -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET); \
			gsutil versioning set on gs://$(DEPLOY_BUCKET); \
		)

# -- This target triggers the creation of the URL SUFFIX for Modules
create-suffix:
	@echo "[$@] :: creating suffix..."
	@gsutil -q stat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION) || \
		gcloud builds submit \
		--project $(PROJECT) \
		--config cloudbuild.yaml \
		--substitutions=_PROJECT=$(PROJECT),_DEPLOY_BUCKET=$(DEPLOY_BUCKET),_REGION=$(REGION) \
		--suppress-logs
