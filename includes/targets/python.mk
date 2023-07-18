# ======================================================================================== #
#    ___      _   _               _____       _        _____                  _
#   | _ \_  _| |_| |_  ___ _ _   |_   _|__ __| |_ ___ |_   _|_ _ _ _ __ _ ___| |_ ___
#   |  _/ || |  _| ' \/ _ \ ' \    | |/ -_|_-<  _(_-<   | |/ _` | '_/ _` / -_)  _(_-<
#   |_|  \_, |\__|_||_\___/_||_|   |_|\___/__/\__/__/   |_|\__,_|_| \__, \___|\__/__/
#        |__/                                                       |___/
# ======================================================================================== #
# This file contains the targets to install and test locally a Python application

# ---------------------------------------------------------------------------------------- #
# -- < Help > --
# ---------------------------------------------------------------------------------------- #
# -- targets that must always be run
.PHONY: help clean-test prepare-test test e2e-test

# -- this will extend the main help to describe targets in this file
define HERE_HELP_PYTHON_TESTS :=
clean-test        Clean the intermediate files stored locally during testing
prepare-test      Prepare the tests by installing requirements and building the env file
test              Test the application by launching linters and unit tests
e2e-test          Run end-to-end tests for module. If E2E_TEST_GROUP is set, run only tests in this subfolder
endef
export HERE_HELP_PYTHON_TESTS

help::
	@echo "$$HERE_HELP_PYTHON_TESTS"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PYTHON_SRC         := src
PYTHON_E2E_TESTS   := e2e-tests

SRC_FILES          := $(shell find $(PYTHON_SRC) -type f \
	! -name '*.pyc' -and ! -name '*_test.py' -and ! -name conftest.py \
	2>/dev/null \
)
TEST_FILES         := $(shell find $(PYTHON_SRC) -type f \
	-name '*_test.py' -or -name conftest.py \
	2>/dev/null \
)
E2E_TEST_FILES     := $(shell find $(PYTHON_E2E_TESTS) -type f \
	! -name '*.pyc' \
	2>/dev/null \
)
TEST_ENV           := test_env.sh
STATIC_TEST_ENV    := .env

VIRTUAL_ENV            := .venv
BUILD_REQUIREMENTS     := requirements.txt
TESTS_REQUIREMENTS     := requirements-test.txt
E2E_TESTS_REQUIREMENTS := requirements-e2etest.txt

ifeq ($(wildcard $(BUILD_REQUIREMENTS)),)
$(error ERROR: $(BUILD_REQUIREMENTS) file not found in modules/$(MODULE_DIR_NAME))
endif

PYLINTRC_LOCATION   = ../../.pylintrc
COVERAGERC_LOCATION = ../../.coveragerc


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target removes the intermediate files used for testing
clean-test:
	@echo "[$@] :: Cleaning the intermediate files for testing"
	@for file in \
			$(STATIC_TEST_ENV) \
			$(VIRTUAL_ENV) \
			$(TESTS_REQUIREMENTS) \
			.coverage \
			.pytest_cache \
		;do \
			[ -e $${file} ] && ( echo -e "\t$${file}"; rm -rf "$${file}"; ) || true; \
		done


# ---------------------------------------------------------------------------------------- #
# -- < Installing > --
# ---------------------------------------------------------------------------------------- #
PYTHON_LIB_NAME        = loreal
PYTHON_LIB_ARTREG_PATH = europe-west1-python.pkg.dev/itg-btdpshared-gbl-ww-pd/pydft-artreg-pythonrepository-ew1-pd/simple/
PYTHON_LIB_INDEX_URL   = https://oauth2accesstoken:$(shell gcloud auth print-access-token)@$(PYTHON_LIB_ARTREG_PATH)

define HERE_TESTS_REQUIREMENTS :=
pytest==7.2.1
pytest-cov==4.0.0
bandit==1.7.4
black==23.1.0
pylint==2.16.2
pytest-parallel==0.1.1
pytest-repeat==0.9.1
dependency-check==0.6.0
pydocstyle==6.3.0
mypy==1.1.1
endef
export HERE_TESTS_REQUIREMENTS

define HERE_BASE_TEST_ENV :=
APP_NAME=$(APP_NAME)
APP_NAME_SHORT=$(APP_NAME_SHORT)
MODULE_NAME=$(MODULE_NAME)
MODULE_NAME_SHORT=$(MODULE_NAME_SHORT)
PROJECT=$(PROJECT)
PROJECT_ENV=$(PROJECT_ENV)
PROJECT_NUMBER=$(shell \
	gcloud projects describe $(PROJECT) --format=json | jq -r '.projectNumber // ""' \
)
CLOUDRUN_URL_SUFFIX=$(CLOUDRUN_URL_SUFFIX)
DB_HOST=localhost
endef
export HERE_BASE_TEST_ENV


# -- this target builds the Python test requirements
prepare-test: $(STATIC_TEST_ENV) $(TESTS_REQUIREMENTS) $(VIRTUAL_ENV)

# Builds a static env file with plain values for docker or a debugger. Always re-build to ensure freshness.
# Steps:
# 1. In a tmp file, list every env variable alongside their reference. E.g. `A=$A`
# 2. After sourcing test env files, substitute in tmp file every reference by their value. E.g. `A=(1)`
#   N.B. To be usable in a shell script again, its values would need to be escaped. E.g. `A=\(1\)`
.PHONY: $(STATIC_TEST_ENV)
$(STATIC_TEST_ENV):
	@echo "[prepare-test] :: Creating environment file $(STATIC_TEST_ENV) for tests"
	@set -euo pipefail; \
		tmp_env_file=/tmp/$(MODULE_DIR_NAME)$(STATIC_TEST_ENV)_intermediate; \
		( \
			echo "$$HERE_BASE_TEST_ENV" && (cat $(TEST_ENV) 2>/dev/null || true) \
		) \
			| grep -oE '^(export )?([A-Za-z_]+[A-Za-z0-9_]*)=' \
			| sed -E 's/^(export )?([A-Za-z_]+[A-Za-z0-9_]*)=$$/\2=$$\2/' \
			> $$tmp_env_file; \
		\
		set -o allexport; \
		eval "$$HERE_BASE_TEST_ENV"; [ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		set +o allexport; \
		echo "$$(eval \
			"echo \"$$(cat $$tmp_env_file)\"" \
		)" \
			> $(STATIC_TEST_ENV);

$(TESTS_REQUIREMENTS):
	@echo "[prepare-test] :: creating requirements for test"
	@echo "$$HERE_TESTS_REQUIREMENTS" > $@

# BEWARE: hack using a trap to ensure the virtual env directory will be remove
# if the installation process fails
$(VIRTUAL_ENV): $(TESTS_REQUIREMENTS) $(BUILD_REQUIREMENTS)
	@echo "[prepare-test] :: Checking requirements of module $(MODULE_NAME)"
	@set -euo pipefail; \
		if ( \
			cat $(BUILD_REQUIREMENTS) \
				| sed -E -e 's/#.*//' -e 's/ +$$//' -e '/^$$/d' -e 's/--\w+ .*//' \
				| grep -vqE '[~<=>]='; \
		); then \
			echo '[prepare-test] :: At least one dependency has no version specified in $(BUILD_REQUIREMENTS).'; \
			exit 1; \
		fi;
	@echo "[prepare-test] :: Creating the virtual environment"
	@set -euo pipefail; \
		function remove_me() { if (( $$? != 0 )); then rm -fr $@; fi; }; \
		trap remove_me EXIT; \
		rm -rf $@; \
		$(PYTHON_BIN) -m venv $@; \
		source $@/bin/activate; \
		pip install -r $(TESTS_REQUIREMENTS); \
		pip install --no-cache-dir --extra-index-url $(PYTHON_LIB_INDEX_URL) -r $(BUILD_REQUIREMENTS);


# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target triggers the tests
test: prepare-test
	@set -euo pipefail; \
		if [ ! -d $(PYTHON_SRC) ]; then \
			echo "[$@] :: Nothing to do since $(PYTHON_SRC)/ is empty"; \
			exit 0; \
		fi; \
		source $(VIRTUAL_ENV)/bin/activate; \
		set -o allexport; \
		eval "$$HERE_BASE_TEST_ENV"; [ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		set +o allexport; \
		\
		echo "[$@] :: Testing module $(MODULE_NAME)"; \
		pylint --reports=n --rcfile=$(PYLINTRC_LOCATION) $(PYTHON_SRC); \
		black --check --diff $(PYTHON_SRC); \
		bandit -r -x '*_test.py' -f screen $(PYTHON_SRC); \
		$(PYTHON_BIN) -m pytest -vv \
			--cov $(PYTHON_SRC) \
			--cov-config=$(COVERAGERC_LOCATION) \
			--cov-report term-missing \
			--cov-fail-under 100 \
			$(PYTHON_SRC);

# -- this target triggers the e2e-tests
# If set, only run tests of this test group that are the subfolder of same name in PYTHON_E2E_TESTS
E2E_TEST_GROUP ?=

e2e-test: prepare-test
	@set -euo pipefail; \
		if [ ! -d $(PYTHON_E2E_TESTS) ]; then \
			echo "[$@] :: Nothing to do since $(PYTHON_E2E_TESTS)/ is empty"; \
			exit 0; \
		fi; \
		set -o allexport; \
		eval "$$HERE_BASE_TEST_ENV"; [ -f $(TEST_ENV) ] && source ./$(TEST_ENV); \
		set +o allexport; \
		\
		source $(VIRTUAL_ENV)/bin/activate; \
		if [ -f $(E2E_TESTS_REQUIREMENTS) ]; then \
			pip install --upgrade --force-reinstall -r $(E2E_TESTS_REQUIREMENTS); \
		fi; \
		if [ -z "$(E2E_TEST_GROUP)" ]; then \
			echo "[$@] :: Running end-to-end tests for module $(MODULE_NAME)"; \
			pylint --reports=n --rcfile=$(PYLINTRC_LOCATION) $(PYTHON_E2E_TESTS); \
			black --check --diff $(PYTHON_E2E_TESTS); \
			$(PYTHON_BIN) -m pytest -vv \
				$(PYTHON_E2E_TESTS); \
		else \
			echo "[$@] :: Running end-to-end tests for module $(MODULE_NAME) on subfolder $(E2E_TEST_GROUP)"; \
			$(PYTHON_BIN) -m pytest -vv \
				$(wildcard $(PYTHON_E2E_TESTS)/conftest.py) \
				$(PYTHON_E2E_TESTS)/$(E2E_TEST_GROUP); \
		fi;
