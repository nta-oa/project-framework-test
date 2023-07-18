# ======================================================================================== #
#     ___ _             _   ___             _____                  _
#    / __| |___ _  _ __| | | _ \_  _ _ _   |_   _|_ _ _ _ __ _ ___| |_ ___
#   | (__| / _ \ || / _` | |   / || | ' \    | |/ _` | '_/ _` / -_)  _(_-<
#    \___|_\___/\_,_\__,_| |_|_\\_,_|_||_|   |_|\__,_|_| \__, \___|\__/__/
#                                                        |___/
# ======================================================================================== #
# This file contains targets for the Google Cloud Run (GCR) module type
# Dockerfile is MANDATORY

ifeq ($(wildcard $(DOCKERFILE)),)
$(error $(DOCKERFILE) file not found)
endif

BUILD_REVISION   := revision
GCR_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES) $(DOCKERFILE)

# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target removes the intermediate files used for building the application
clean-app:
	@echo "[$@] :: Cleaning the intermediate files for building"
	@for file in \
			$(BUILD_REVISION) \
		;do \
			[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
		done


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
# -- target triggering the build of a Cloud Run docker image
build-app: $(BUILD_REVISION)
$(BUILD_REVISION): $(GCR_DEPENDENCIES)
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
# -- this target runs tests on module Dockerfile with Hadolint
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


# --this target runs the application locally in a container using its docker image
RUN_PORT ?= 8080

DOCKER_ENV_FILE := /tmp/$(MODULE_DIR_NAME)_docker_env

local-test: $(STATIC_TEST_ENV) build-app
	@echo "[$@] :: Running the local GCR $(MODULE_NAME)";
	@cp $(STATIC_TEST_ENV) $(DOCKER_ENV_FILE); \
		if [ -f creds.json ]; then \
			echo 'GOOGLE_CLOUD_PROJECT=$(PROJECT)'                  >> $(DOCKER_ENV_FILE); \
			echo 'GOOGLE_APPLICATION_CREDENTIALS=/creds/creds.json' >> $(DOCKER_ENV_FILE); \
		else \
			echo "WARNING: No gcloud creds.json file found in modules/$(MODULE_DIR_NAME)/." \
				"It must be generated or can be copied from ~/.config/gcloud"; \
		fi;
	@docker run -it \
		-v $(shell pwd):/creds \
		-v $(shell pwd)/$(PYTHON_SRC):/app \
		-e DB_HOST=$(SANDBOX_DB_HOST) \
		-e LOCAL_TEST=1 \
		-e DEBUG_FLAG=--reload \
		--env-file $(DOCKER_ENV_FILE) \
		-p $(RUN_PORT):8080 \
		-t gcr.io/$(PROJECT)/$(MODULE_NAME):latest


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
# ---------------------------------------------------------------------------------------- #
# -- this target deploys the docker image for module in Google Cloud registry
deploy-app:
	@echo "[$@] :: Pushing docker image for module $(MODULE_NAME)"
	@docker push gcr.io/$(PROJECT)/$(MODULE_NAME):latest;


# -- this target deploys the module API as proxy in Apigee
# When ready, use --fail-with-body instead of -s, -output and --write-out.in last curl request.
# Not available in the current Ubuntu 2020.04 version (7.68)
deploy-apigee:
	@set -euo pipefail; \
	if ! [[ -f $(API_CONF_FILE) && $(ENV) =~ ^(dv|qa|np|pd)$$ ]]; then \
		echo "[$@] :: Nothing to do"; \
		exit 0; \
	fi; \
	if ! (jq -e '.versions' $(API_CONF_FILE) >/dev/null); then \
		echo "[$@] :: ERROR. No versions declared in $(API_CONF_FILE)"; \
		exit 0; \
	fi; \
	API_VERSIONS=$$(jq -rc .versions                   $(API_CONF_FILE)); \
	IS_FRONT_PROJECT=$$(jq -r .is_front_project        $(API_CONF_FILE)); \
	API_CONF=$$(jq 'del(.is_front_project, .versions)' $(API_CONF_FILE)); \
	\
	echo "[$@] :: Retrieving target info and credentials"; \
	TARGET_PROJECT=$$( \
		[ $$IS_FRONT_PROJECT = true ] && echo $(FRONT_PROJECT) || echo $(PROJECT) \
	); \
	TARGET="$$( \
		gcloud run services describe \
			$(APP_NAME_SHORT)-gcr-$(MODULE_NAME_SHORT)-$(REGION_ID)-$(PROJECT_ENV) \
			--project $${TARGET_PROJECT} \
			--region=$(REGION) \
			--format='value(status.address.url)' \
	)"; \
	PAYLOAD=$$( \
		jq -rc '.target = "'$$TARGET'" | .environment = "$(PROJECT_ENV)"' <<< "$$API_CONF" \
	); \
	TOKEN=$$( \
		curl -s -f -X POST "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$(APIGEE_DEPLOY_SA):generateIdToken" \
			--header 'Content-Type: application/json' \
			--header "Authorization: Bearer $$(gcloud auth print-access-token)" \
			--data '{"audience": "'$$TARGET'"}' \
		| jq -r '.token' \
	); \
	\
	echo "[$@] :: Deploying API version(s) to Apigee: $$API_VERSIONS"; \
	n=$$(jq 'length' <<< "$$API_VERSIONS"); \
	i=1; \
	for version in $$(jq -rc '.[]' <<< "$$API_VERSIONS"); do \
		API_NAME=$$(jq -r .api_name         <<< "$$API_CONF")-$$version; \
		API_BASEPATH=$$(jq -r .api_basepath <<< "$$API_CONF")/$$version; \
		TARGET_BASEPATH=/$$version; \
		\
		echo "[$@] :: ($$i/$$n) Deploying proxy to Apigee: $$API_NAME"; \
		echo "[$@] :: Retrieving swagger in base64"; \
		APIGEE_PAYLOAD_FILE=$${API_NAME}_$(APIGEE_PAYLOAD); \
		curl -s -f "$${TARGET}$${TARGET_BASEPATH}/swagger.json" \
			--header "Authorization: Bearer $$TOKEN" \
			| base64 | xargs | sed "s/ //g" \
			| jq -R "$$PAYLOAD"' + { "base64_swagger": . }' \
			| jq '.api_name="'$$API_NAME'" | .api_basepath="'$$API_BASEPATH'" | .target_basepath="'$$TARGET_BASEPATH'"' \
			> $$APIGEE_PAYLOAD_FILE; \
		\
		echo "[$@] :: Sending the deploy request"; \
		response_payload_file=$${API_NAME}_$(APIGEE_RESPONSE_PAYLOAD); \
		http_code=$$( \
			curl -s -X POST $(APIGEE_DEPLOYER_ENDPOINT)/publish \
			--header "Authorization: Bearer $$(gcloud auth print-access-token)" \
			--header "Content-Type: application/json" \
			--data @$$APIGEE_PAYLOAD_FILE \
			--raw --output $$response_payload_file \
			--write-out "%{http_code}"; \
		); \
		cat $$response_payload_file | jq 2>/dev/null || (cat $$response_payload_file && echo ""); \
		if [[ $$http_code != 200 ]]; then \
			echo "[$@] :: ERROR. $$http_code - Failed to deploy proxy: $$API_NAME"; \
		else \
			echo "[$@] :: SUCCESS. Proxy deployed to Apigee: $$API_NAME"; \
			rm $$APIGEE_PAYLOAD_FILE $$response_payload_file; \
		fi; \
		i=$$((i+1)) && echo ""; \
	done;
