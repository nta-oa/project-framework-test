#!/usr/bin/env bash

# =======================================================================================
#
# --- Pre-Push hook ---
#
# This hook is called when the push command is called before
# and comes after the btdp pre-push script
#
# =======================================================================================


HOOK_PATH=$(git config --get core.hooksPath)
HOOK_NAME=$1
PROJECT_HOOK_COMMANDS=$2
HOOK_CONTENTS="${PROJECT_HOOK_COMMANDS} && sh ${HOOK_PATH}/btdp-hooks/${HOOK_NAME}"
HOOK_FILENAME="${HOOK_PATH}/${HOOK_NAME}"
CURRENT_DIRECTORY="$(dirname "$(realpath "$0")")"

source "${CURRENT_DIRECTORY}/tools/mergeHooks.sh"
source "${CURRENT_DIRECTORY}/tools/colors.sh"

add_c4e_hook

unset HOOK_PATH HOOK_NAME PROJECT_HOOK_COMMANDS HOOK_CONTENTS HOOK_FILENAME CURRENT_DIRECTORY
