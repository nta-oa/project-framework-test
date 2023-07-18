# ======================================================================================== #
#     ___ _             _   ___             _   _            _____                  _
#    / __| |___ _  _ __| | | __|  _ _ _  __| |_(_)___ _ _   |_   _|_ _ _ _ __ _ ___| |_ ___
#   | (__| / _ \ || / _` | | _| || | ' \/ _|  _| / _ \ ' \    | |/ _` | '_/ _` / -_)  _(_-<
#    \___|_\___/\_,_\__,_| |_| \_,_|_||_\__|\__|_\___/_||_|   |_|\__,_|_| \__, \___|\__/__/
#                                                                         |___/
# ======================================================================================== #
# This file contains targets for the Google Cloud Function (GCF) module type
# No Dockerfile needed

GCF_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES)
GCF_DIST         := dist
GCF_ARCHIVE      := /tmp/$(GCF_DIST)_$(MODULE_NAME).zip

# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target removes the intermediate files used for building the application
clean-app:
	@echo "[$@] :: Cleaning the intermediate files for building"
	@for file in $(BUILD_REVISION) $(GCF_DIST) $(GCF_ARCHIVE) \
		;do \
			[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
		done

# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
GCF_DIST_FILES := $(shell find $(GCF_DIST) -type f 2>/dev/null)

PYTHON_LIB_VERSION_REGEX := $(PYTHON_LIB_NAME)([~<=>][^\#]+)?


# -- target building the GCF distributions whenever changes occur on source files
build-app: $(BUILD_REVISION)
	@echo "[$@] :: Ready to deploy module $(MODULE_NAME)";

# whenever the distributions or archive are altered or missing, re-build from scratch
$(GCF_DIST) $(GCF_DIST_FILES): $(GCF_DEPENDENCIES)
$(GCF_ARCHIVE): $(GCF_DIST) $(GCF_DIST_FILES)

$(BUILD_REVISION): $(GCF_ARCHIVE) $(GCF_DIST) $(GCF_DIST_FILES) $(GCF_DEPENDENCIES)
# Prepare distributions
	@echo "[$@] :: building GCF distributions in $(GCF_DIST)/"
	@rm -rf $(GCF_DIST); mkdir $(GCF_DIST);
## Add source files
	@cd $(PYTHON_SRC); \
		tar -cf - $(SRC_FILES:$(PYTHON_SRC)/%=%) | (cd ../$(GCF_DIST)/; tar -xf -);
## Add requirements. If python lib is not mentionned, copy as-is.
## Else, download its wheel and substitute its entry in requirements.
	@set -euo pipefail; \
		PYTHON_LIB=$$( \
			cat $(BUILD_REQUIREMENTS) | grep -oE --max-count 1 "$(PYTHON_LIB_VERSION_REGEX)" | xargs \
			|| echo -n "" \
		); \
		if [ -z "$$PYTHON_LIB" ]; then \
			cp $(BUILD_REQUIREMENTS) $(GCF_DIST)/requirements.txt; \
			exit 0; \
		fi; \
		\
		echo "[$@] :: downloading wheel for '$$PYTHON_LIB' and substituting it in requirements"; \
		cd $(GCF_DIST); \
		pip download "$$PYTHON_LIB" --no-deps --index-url $(PYTHON_LIB_INDEX_URL); \
		PYTHON_LIB_WHEEL=$$( \
			ls -1 $(PYTHON_LIB_NAME)*.whl | head -1 \
		); \
		cd -; \
		cat $(BUILD_REQUIREMENTS) | sed -E "s/$$PYTHON_LIB/.\/$$PYTHON_LIB_WHEEL/" \
			> $(GCF_DIST)/requirements.txt;
# Build archive
	@echo "[$@] :: building GCF archive at $(GCF_ARCHIVE)"; \
		rm -rf $(GCF_ARCHIVE); \
		cd $(GCF_DIST) && zip -r $(GCF_ARCHIVE) ./*;
# Compute revision
	@find $(GCF_DIST) -type f -exec cat {} \; \
		| md5sum | cut -d ' ' -f 1 \
		> $(BUILD_REVISION);


scan-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"


# ---------------------------------------------------------------------------------------- #
# -- < Local Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target runs tests on module Dockerfile with Hadolint. Nothing to do for functions
hadolint-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"


GCF_PORT ?= 8080
GCF_SRC  ?= $(PYTHON_SRC)/main.py
GCF_NAME ?= main

# -- target to locally run a cloud function using the functions_framework
local-test:
	@echo "[$@] :: running the local GCF $(MODULE_NAME)"
	@export LOCAL_TEST=1; \
		set -o allexport; \
		eval "$$HERE_BASE_TEST_ENV"; [ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		set +o allexport; \
		functions_framework --source=$(GCF_SRC) --target=$(GCF_NAME) --port=$(GCF_PORT) --debug


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
# ---------------------------------------------------------------------------------------- #
# -- target pushing the GCF archive to the dedicated location in the deployment bucket
deploy-app:
	@echo "[$@] :: Pushing GCF distributions for module $(MODULE_NAME)"
	@gsutil cp -v $(GCF_ARCHIVE)     gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src_$$(cat $(BUILD_REVISION)).zip; \
	 gsutil cp -v $(BUILD_REVISION)  gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/gcf-src-hash;


deploy-apigee:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
