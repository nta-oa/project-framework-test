# ======================================================================================== #
#    __  __      _        __ _ _       ___                           _    _ _
#   |  \/  |__ _| |_____ / _(_) |___  | _ \_ _ ___ _ _ ___ __ _ _  _(_)__(_) |_ ___ ___
#   | |\/| / _` | / / -_)  _| | / -_) |  _/ '_/ -_) '_/ -_) _` | || | (_-< |  _/ -_|_-<
#   |_|  |_\__,_|_\_\___|_| |_|_\___| |_| |_| \___|_| \___\__, |\_,_|_/__/_|\__\___/__/
#                                                            |_|
# ======================================================================================== #
# N.B. It must be included at the top of each Makefile to check REQUIRED_EXECUTABLES
# and to define base variables.

# ---------------------------------------------------------------------------------------- #
# -- < Checks > --
# ---------------------------------------------------------------------------------------- #
# -- Verify required shell executable
REQUIRED_EXECUTABLES := gcloud docker jq git python3.10 bash terraform md5sum tar zip unzip
$(foreach exec, $(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)),,$(error No $(exec) in PATH. Please verify it is installed)) \
)

# -- Verify make version
MINIMAL_MAKE_VERSION := 4.1

ifeq ($(MAKE_VERSION),)
$(error "ERROR: Could not extract the version for Make from local context.")
endif

OLDER_MAKE_VERSION := $(shell \
	printf "%s\n" "$(MAKE_VERSION)" "$(MINIMAL_MAKE_VERSION)" | sort --version-sort | head -1 \
)

ifneq ($(OLDER_MAKE_VERSION),$(MINIMAL_MAKE_VERSION))
$(error \
	Only versions of GNU Make >=$(MINIMAL_MAKE_VERSION) are supported; but $(MAKE_VERSION) \
	was found in the active shell. Please verify your local configuration and check the \
	README.md for the 'Setup of the local environment' link.)
endif


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(ENV),)
$(error ENV is not set)
endif

# -- load the configuration environment file
ENV_DIR         := $(ROOT_DIR)/environments
ENV_FILE        := $(ENV_DIR)/$(ENV).json
OPS_ENV_LIST    := ops-np ops-qa ops-cicd

ifeq ($(wildcard $(ENV_FILE)),)
$(error ENV $(ENV): env file not found)
endif

# -- compute application variables
ifeq ($(wildcard $(ROOT_DIR)/.app_name),)
$(shell cd $(ROOT_DIR)/environments && ./instantiate-template.sh $(ROOT_DIR))
endif

ifeq ($(filter $(ENV), $(OPS_ENV_LIST)),)
# read value from app_name file for standard projects
APP_NAME        := $(shell cat $(ROOT_DIR)/.app_name)
else
# read value from env file for ops projects
APP_NAME        := $(shell jq -r '.app_name' $(ENV_FILE))
endif

APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")


# ---------------------------------------------------------------------------------------- #
# -- < Base Targets > --
# ---------------------------------------------------------------------------------------- #
# -- this target deletes all untracked files from the git repository. So beware.
.PHONY: reinit
reinit:
	@read -r -p \
		"[$@] :: WARNING: All untracked files will be deleted from the local repository. Are you sure? [y/N]" prompt; \
		prompt_lowecase=$$(echo $$prompt | tr '[:upper:]' '[:lower:]'); \
		if [[ ! "$$prompt_lowecase" =~ ^(yes|y)$$ ]]; then \
			echo "[$@] :: CANCELLED: No file were removed."; \
			exit 0; \
		fi; \
		git clean -f $(shell pwd); \
		git clean -fX $(shell pwd);
