#!/usr/bin/bash

set -eu

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

validate_email() {
    local useremail=$1
    [[ "$useremail" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && return 0 || return 1  
}

trap 'echo -e "\n${RED}interrupted${NC}"; exit 1' INT TERM

echo -e "${YELLOW}this script will install and configure git, gh and tig${NC}"
echo

echo -e "${YELLOW}installing git and tig...${NC}"
sudo apt update
sudo apt install -y git tig gh
echo 
while :; do
    read -rep "enter your email: " useremail
    read -rep "enter your name : " username
    echo

    if validate_email "$useremail" && [[ -n "$username" ]]; then
        echo -e "email: ${GREEN}$useremail${NC}"
        echo -e "name : ${GREEN}$username${NC}"
        read -rp "are these details correct? [Y/n] " confirm
        [[ "$confirm" =~ [Nn] ]] && continue
        break
    else
        echo -e "${RED}invalid input${NC}"
        if ! validate_email "$useremail"; then
            echo -e "${RED}invalid email format${NC}"
        fi
        [[ ! -n "$username" ]] && echo -e "${RED}name cannot be empty${NC}"
    fi
done

echo -e "\n${YELLOW}configuring git...${NC}"
git config --global user.email "$useremail"
git config --global user.name "$username"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global --add safe.directory '*'
echo

while :; do
    read -rp "set up ssh commit signing? [Y/n] " sshsignconf
    [[ $sshsignconf =~ [Nn] ]] && break
    echo
    echo -e "${YELLOW}setting up ssh commit signing${NC}"
    git config --global gpg.format ssh
    echo
    read -rp "enter path to signing key: " signingkeypath
    git config --global user.signingkey "$signingkeypath"
    echo -e "${GREEN}ssh commit signing done${NC}"
    break
done

echo
echo -e "${GREEN}git configured!${NC}"
