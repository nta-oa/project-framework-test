# ======================================================================================== #
#            ___                           __   __        _      _    _
#           / __|___ _ __  _ __  ___ _ _   \ \ / /_ _ _ _(_)__ _| |__| |___ ___
#          | (__/ _ \ '  \| '  \/ _ \ ' \   \ V / _` | '_| / _` | '_ \ / -_|_-<
#           \___\___/_|_|_|_|_|_\___/_||_|   \_/\__,_|_| |_\__,_|_.__/_\___/__/
#
# ======================================================================================== #

PYTHON_BIN := python3.8


# ---------------------------------------------------------------------------------------- #
# -- < Environment fail fast checks > --
# ---------------------------------------------------------------------------------------- #
include $(ROOT_DIR)/includes/failfast-checks.mk


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PROJECT_ENV     := $(shell jq -r '.project_env'         $(ENV_FILE))
PROJECT_DATA    := $(shell jq -r '.project_data'        $(ENV_FILE))
PROJECT         := $(shell jq -r '.project'             $(ENV_FILE))
DOMAIN          := $(shell jq -r '.domain'              $(ENV_FILE))

VERSION         := $(shell jq -r '.version'             $(PKG_FILE))
APP_NAME        := $(shell jq -r '.name'                $(PKG_FILE))
APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")
# -- bucket definitions
DEPLOY_BUCKET   := $(APP_NAME_SHORT)-gcs-deploy-eu-$(PROJECT_ENV)

# -- location variables
LOCATION_ID     := $(shell jq -r '.location_id // "europe-west1"' $(ENV_FILE))
ZONE            := $(shell jq -r '.zone // "europe-west1-b"'      $(ENV_FILE))
ZONE_ID         := $(shell jq -r '.zone_id'                       $(ENV_FILE))
REGION          := $(shell jq -r '.region // ("$(ZONE)"|sub("-[a-z]$$"; ""))' $(ENV_FILE))
REGION_ID       := $(shell jq -r '.region_id'                     $(ENV_FILE))

# -- computed location variables
ifeq ($(ZONE_ID),null)
ZONE_ID         := $(shell sed -E "s/(.).*-(.).*([0-9])-([a-z])$$/\1\2\3\4/" <<< $(ZONE))
endif
ifeq ($(REGION_ID),null)
REGION_ID       := $(shell sed -E "s/(.*)[a-z]$$/\1/" <<< $(ZONE_ID))
endif

# -- determine code branch, displays "current" if not git history is available
BRANCH := $(shell \
	if [ "$(BRANCH_NAME)" != "" ]; then \
		echo -n "${BRANCH_NAME}"; \
	else \
		git rev-parse --abbrev-ref HEAD || echo -n "current" ; \
	fi;)


# ---------------------------------------------------------------------------------------- #
# -- < Feedback > --
# ---------------------------------------------------------------------------------------- #
# -- display environment variables (always printed)
$(info $(shell printf "=%.s" $$(seq 100)))
$(info -- $(CURRENT_MAKEFILE): Environment variables)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info ENV               = $(ENV))
$(info ENV_FILE          = $(ENV_FILE))
$(info APP_NAME          = $(APP_NAME))
$(info APP_NAME_SHORT    = $(APP_NAME_SHORT))
$(info PROJECT           = $(PROJECT))
$(info PROJECT_ENV       = $(PROJECT_ENV))
$(info DOMAIN            = $(DOMAIN))
$(info VERSION           = $(VERSION))
$(info IS_SANDBOX        = $(IS_SANDBOX))
$(info DEPLOY_BUCKET     = $(DEPLOY_BUCKET))
$(info LOCATION_ID       = $(LOCATION_ID))
$(info REGION            = $(REGION))
$(info REGION_ID         = $(REGION_ID))
$(info ZONE              = $(ZONE))
$(info ZONE_ID           = $(ZONE_ID))

$(info $(shell printf "=%.s" $$(seq 100)))
