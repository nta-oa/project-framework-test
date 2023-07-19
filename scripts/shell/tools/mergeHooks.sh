#!/usr/bin/env bash

function write_hook () {
    npx husky add $1 "${HOOK_CONTENTS}"
}

function generate_c4e_hook () {
    echo "${HOOK_PATH}/btdp-hooks/${HOOK_NAME}"
    if test -f "${HOOK_PATH}/btdp-hooks/${HOOK_NAME}"; then
        echo -e "\n${RED}Internal error: try running \"npm run hooks:clean\" then reinstall all hooks${NC}\n"
        rm -f "${HOOK_FILENAME}.tmp"
        exit 1
    else
        mv "${HOOK_FILENAME}" "${HOOK_PATH}/btdp-hooks/${HOOK_NAME}"
        rm -f "${HOOK_FILENAME}.tmp"
        write_hook $HOOK_FILENAME ""
    fi
}

function merge_hooks () {
    if cmp --silent "${HOOK_FILENAME}.tmp" ${HOOK_FILENAME}; then
        rm -f "${HOOK_FILENAME}.tmp"
        echo -e "\n${ORANGE}Warning This hook already exists${NC}\n"
        exit 1
    else
        generate_c4e_hook
    fi
}

function add_c4e_hook () {

    if test -f "${HOOK_FILENAME}"; then
        write_hook ${HOOK_FILENAME}.tmp
        merge_hooks
    else
        if test -f "${HOOK_PATH}/btdp-hooks/${HOOK_NAME}"; then
            echo -e "\n${RED}Internal error: try running \"npm run hooks:clean\" then reinstall all hooks${NC}\n"
            rm -f "${HOOK_FILENAME}.tmp"
            exit 1
        else
            npx husky add $HOOK_FILENAME "${PROJECT_HOOK_COMMANDS}"
        fi
    fi

}
