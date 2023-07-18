# ======================================================================================== #
#     ___ _             _   ___      _ _    _   _____                  _
#    / __| |___ _  _ __| | | _ )_  _(_) |__| | |_   _|_ _ _ _ __ _ ___| |_ ___
#   | (__| / _ \ || / _` | | _ \ || | | / _` |   | |/ _` | '_/ _` / -_)  _(_-<
#    \___|_\___/\_,_\__,_| |___/\_,_|_|_\__,_|   |_|\__,_|_| \__, \___|\__/__/
#                                                            |___/
# ======================================================================================== #
# This file contains targets for the Google Cloud Build (GCB) module type
# Dockerfile is OPTIONAL

ifeq ($(wildcard $(DOCKERFILE)),)
$(info No $(DOCKERFILE) found for $(MODULE_NAME))

clean-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
build-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
scan-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
hadolint-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
local-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
deploy-app:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"

else # >>>> define targets only if Dockerfile exist

# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target removes the intermediate files used for building the application
clean-app:
	@echo "[$@] :: Cleaning the intermediate files for building"
	@for file in $(BUILD_REVISION) \
		;do \
			[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
		done


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
GCB_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES) $(DOCKERFILE)

# -- this target triggers the build of a Cloud Run docker image
build-app: $(BUILD_REVISION)
$(BUILD_REVISION): $(GCB_DEPENDENCIES)
	@echo "[$@] :: Building the GCR image for module $(MODULE_NAME)"
	@set -euo pipefail; \
		docker build \
			--platform linux/amd64 \
			--tag gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
			--build-arg PROJECT=$(PROJECT) \
			--build-arg PROJECT_ENV=$(PROJECT_ENV) \
			--build-arg PYTHON_LIB_INDEX_URL=$(PYTHON_LIB_INDEX_URL) \
			--iidfile $(BUILD_REVISION) \
			.


# -- this target scans the built docker image for vulnerability
scan-app: $(BUILD_REVISION)
	@echo "[$@] :: container vulnerability scanning"
	@set -euo pipefail; \
	SCAN_ID=$$( \
		gcloud beta artifacts docker \
			images scan gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
			--location=europe --format='value(response.scan)' \
		); \
	echo "[$@] :: security count"; \
	gcloud beta artifacts docker images \
		list-vulnerabilities $${SCAN_ID} \
		--location=europe \
		--format='value(vulnerability.effectiveSeverity)' \
		| sort |  uniq -c ; \
	echo "[$@] :: security check"; \
	gcloud beta artifacts docker images \
		list-vulnerabilities $${SCAN_ID} \
		--location=europe \
		--format='value(vulnerability.effectiveSeverity)' | \
		if grep -Fxq CRITICAL; \
		then \
			echo 'Vulnerability check FAILED !' && exit 1; \
		else \
			echo "Vulnerability check SUCCEEDED !"; \
		fi;
	@echo "[$@] :: GCR image for module $(MODULE_NAME) built."


# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target run tests on module Dockerfile with Hadolint
hadolint-test:
	@echo "[$@] :: Test $(DOCKERFILE) with hadolint for module $(MODULE_NAME)"
	@if ( \
			docker run --rm -i hadolint/hadolint hadolint \
			--ignore DL3008 \
			--ignore DL3025 \
			- < $(DOCKERFILE) \
		); then \
			echo "[$@] :: No issue detected in $(DOCKERFILE)"; \
		else \
			echo "[$@] :: WARNING: Some issues have been found in $(DOCKERFILE). Please address them..."; \
		fi;


# -- this target runs locally the application for module. Nothing to do for Cloud build
local-test:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
# ---------------------------------------------------------------------------------------- #
deploy-app:
	@echo "[$@] :: Pushing docker image for module $(MODULE_NAME)"
	@docker push gcr.io/$(PROJECT)/$(MODULE_NAME):latest

endif  # <<<< define targets only if Dockerfile exist


deploy-apigee:
	@echo "[$@] :: Nothing to do for TYPE='$(TYPE)'"
