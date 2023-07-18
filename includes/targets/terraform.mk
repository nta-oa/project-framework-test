# ======================================================================================== #
#    _____                  __                 ___       ___   _____                  _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_ _|__ _ / __| |_   _|_ _ _ _ __ _ ___| |_ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   | |/ _` | (__    | |/ _` | '_/ _` / -_)  _(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |___\__,_|\___|   |_|\__,_|_| \__, \___|\__/__/
#                                                                           |___/
# ======================================================================================== #
# This file contains the IaC targets to manage a Terraform infrastructure

# ---------------------------------------------------------------------------------------- #
# -- < Help > --
# ---------------------------------------------------------------------------------------- #
# -- targets that must always be run
.PHONY: help \
	iac-clean-state iac-env \
	iac-clean iac-init iac-prepare iac-plan-clean iac-plan iac-deploy

# -- this extends the main help to describe targets in this file
define HERE_HELP_TERRAFORM_IAC :=
iac-clean-state   Migrate or rework the terraform state to execute safely next plan.
                  It is run before iac-plan and iac-deploy
iac-env           Check if the ENV has changed. And if so, remove the local state to re-init Terraform.
                  It is run before each of the following targets

iac-clean         Clean all the intermediate terraform files stored locally to start from scratch.
iac-init          Initialize the terraform infrastructure
iac-prepare       Prepare the terraform infrastructure by creating the variable files
iac-plan          Produce the terraform plan to visualize what will be changed in the infrastructure
iac-plan-clean    Remove the previous terraform plan
iac-deploy        Proceed to the application of the terraform infrastructure
endef
export HERE_HELP_TERRAFORM_IAC

help::
	@echo "$$HERE_HELP_TERRAFORM_IAC"
	@echo ""


ifeq ($(shell ( test -d $(TF_DIR) ) && echo "found" || echo -n),)
$(info WARNING: No infrastructure. Folder TF_DIR '$(TF_DIR)' was not found)

iac-clean-state::
iac-env:
iac-clean:
	@echo "[$@] :: Nothing to do as no infrastructure was found"
iac-init:
	@echo "[$@] :: Nothing to do as no infrastructure was found"
iac-prepare:
	@echo "[$@] :: Nothing to do as no infrastructure was found"
iac-plan-clean:
	@echo "[$@] :: Nothing to do as no infrastructure was found"
iac-plan:
	@echo "[$@] :: Nothing to do as no infrastructure was found"
iac-deploy:
	@echo "[$@] :: Nothing to do as no infrastructure was found"

else # >>>> define targets only if the IaC folder exist

# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
TF_INIT := $(TF_DIR)/.terraform/terraform.tfstate
TF_ENV  := $(TF_DIR)/.iac-env
TF_VARS := $(TF_DIR)/terraform.tfvars
TF_PLAN := $(TF_DIR)/tfplan

TF_FILES        := $(shell find $(TF_DIR) -type f \
	-name '*.tf' | sed -E "s+^\./++" \
	2>/dev/null \
)
TF_CONFIG_FILES := $(shell find $(TF_DIR) -type f \
	-name '*.json' -o -name '*.yaml' -o -name '*.txt' | sed -E "s+^\./++" \
	2>/dev/null \
)


# ---------------------------------------------------------------------------------------- #
# -- < IaC Targets > --
# ---------------------------------------------------------------------------------------- #
# -- this target cleans the terraform state to prepare safe plan
iac-clean-state::

# -- this target cleans the intermediate iac files
iac-clean:
	@echo "[$@] :: Cleaning all IaC intermediate files"
	@for file in $(TF_DIR)/.terraform* $(TF_INIT) $(TF_ENV) $(TF_VARS) $(TF_PLAN)  \
		;do \
			[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
		done

# -- this target check of the ENV has changed and remove the local terraform config is so
iac-env:
	@if [[ $$(cat $(TF_ENV) 2>/dev/null || echo -n) != "$(ENV)" ]]; then \
			echo "[$@] :: ENV has changed. Removing local configuration to re-init terraform"; \
			for file in $(TF_DIR)/.terraform* \
				;do \
					[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
				done; \
		fi;


# -- this target initializes the terraform initialization
iac-init: $(TF_INIT)
$(TF_INIT): iac-env
	@set eu -o pipefail; \
		if [ -d $(TF_DIR)/.terraform ]; then \
			echo "[iac-init] :: Terraform has already been initialized"; \
			exit 0; \
		fi; \
		\
		function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
		trap remove_me EXIT; \
		echo "[iac-init] :: Initializing terraform"; \
		echo "$(ENV)" > $(TF_ENV); \
		cd $(TF_DIR); \
		terraform init \
			-backend-config=bucket=$(DEPLOY_BUCKET) \
			-backend-config=prefix=terraform-state/$(TF_MODULE) \
			-input=false;


# -- this target creates the terraform variables file
TYPE           ?=
BUILD_REVISION ?= revision

iac-prepare: $(TF_VARS)
$(TF_VARS): $(wildcard $(BUILD_REVISION)) $(TF_INIT)
	@echo "[iac-prepare] :: Generating the $(TF_VARS) file"
	@set eu -o pipefail; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		case "$(TYPE)" in \
			gcr) \
				echo "revision = \"$$( \
					gcloud container images list-tags gcr.io/$(PROJECT)/$(MODULE_NAME) \
					--quiet --filter tags=latest --format="get(digest)" \
				)\"" >> $(TF_VARS); \
				;; \
			gcf) \
				echo "revision = \"$$( \
					gsutil -m cat gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src-hash \
				)\"" >> $(TF_VARS); \
				;; \
			*) ;; \
		esac


# -- this target creates the TF_PLAN file whenever the variables file and any *.tf
# file have changed
iac-plan-clean:
	@rm -f $(TF_PLAN)

iac-plan: $(TF_PLAN)
$(TF_PLAN): $(TF_VARS) $(TF_FILES) $(TF_CONFIG_FILES) iac-clean-state
	@echo "[iac-plan] :: Planning the IaC deployment for module $(MODULE_NAME)"
	@cd $(TF_DIR); \
		terraform plan \
			-var-file $(shell basename $(TF_VARS)) \
			-out=$(shell basename $(TF_PLAN));


# -- this target only triggers the iac of the designated module
iac-deploy: iac-plan
	@echo "[$@] :: Deploying the IaC for module $(MODULE_NAME)"
	@cd $(TF_DIR); \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));


endif # <<<< define targets only if the IaC folder exist
