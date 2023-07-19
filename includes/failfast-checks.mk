# ======================================================================================== #
#                 ___     _ _   ___        _      ___ _           _
#                | __|_ _(_) | | __|_ _ __| |_   / __| |_  ___ __| |__ ___
#                | _/ _` | | | | _/ _` (_-<  _| | (__| ' \/ -_) _| / /(_-<
#                |_|\__,_|_|_| |_|\__,_/__/\__|  \___|_||_\___\__|_\_\/__/
#
# ======================================================================================== #

# -- default value is sbx for sbx.json environment file
ifeq ($(ENV),)
$(error ENV is not set)
endif

# -- load the configuration environment file
ENV_DIR         := $(ROOT_DIR)/environments
ENV_FILE        := $(ENV_DIR)/$(ENV).json
PKG_FILE        := $(ROOT_DIR)/package.json
OPS_ENV_LIST    := ops-np ops-qa
ifeq ($(wildcard $(ENV_FILE)),)
$(error ENV $(ENV): env file not found)
endif

APP_NAME        := $(shell jq -r '.name' $(PKG_FILE))
APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")
