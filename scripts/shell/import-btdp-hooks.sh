#!/bin/bash

CURRENT_DIRECTORY="$(dirname "$(realpath "$0")")"
source "${CURRENT_DIRECTORY}/tools/colors.sh"

VALIDATE_BTDP_HOOK_PATH=${FALSE}

function generate_hooks() {
    ln -s $1/* .husky/
}

function validate_paths () {
    if test -f "$1/pre-commit"; then
        VALIDATE_BTDP_HOOK_PATH=1
    else
        echo -e "\n ${RED}WRONG PATH: ${NC}select a valid BTDP hooks folder. \n ${ORANGE}If you cloned the repository as instructed the path should end with \".../btdp-git-utils/hooks\" \n ${NC} "
    fi
}

function select_btdp_hook_path () {

    while [[ $VALIDATE_BTDP_HOOK_PATH -eq 0 ]]
    do
        read -p "Enter the path of your local BTDP hooks "  btdp_hook_local_path
        validate_paths $btdp_hook_local_path
        generate_hooks $btdp_hook_local_path
    done
    echo -e "${GREEN}BTDP hook path has been set successfully.${NC}"

}

select_btdp_hook_path

unset CURRENT_DIRECTORY VALIDATE_BTDP_HOOK_PATH btdp_hook_local_path
