#!/usr/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FISH_CONFIG_SOURCE="${SCRIPT_DIR}/config-files/dotconfig/fish/config.fish"
STARSHIP_CONFIG_SOURCE="${SCRIPT_DIR}/config-files/dotconfig/starship.toml"
FISH_CONFIG_DIR="${HOME}/.config/fish"
STARSHIP_CONFIG_DIR="${HOME}/.config"

# backup existing config files
backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak-$(date +%s)"
        echo -e "${YELLOW}backing up existing config: ${file} -> ${backup}${NC}"
        cp "$file" "$backup"
    fi
}

# copy configuration files
copy_configs() {
    mkdir -p "${FISH_CONFIG_DIR}" "${STARSHIP_CONFIG_DIR}"

    if [[ -f "$FISH_CONFIG_SOURCE" ]]; then
        backup_config "${FISH_CONFIG_DIR}/config.fish"
        cp -v "$FISH_CONFIG_SOURCE" "${FISH_CONFIG_DIR}/config.fish"
    else
        echo -e "${RED}error: fish config file not found at ${FISH_CONFIG_SOURCE}${NC}"
        exit 1
    fi

    if [[ -f "$STARSHIP_CONFIG_SOURCE" ]]; then
        backup_config "${STARSHIP_CONFIG_DIR}/starship.toml"
        cp -v "$STARSHIP_CONFIG_SOURCE" "${STARSHIP_CONFIG_DIR}/starship.toml"
    else
        echo -e "${RED}error: starship config file not found at ${STARSHIP_CONFIG_SOURCE}${NC}"
        exit 1
    fi
}

# post-install setup tasks
post_install() {
    if [[ "$SHELL" != "$(command -v fish)" ]]; then
        echo
        read -rp "set fish as default shell? [y/n]" response
        if [[ "$response" =~ [yY] ]]; then
            chsh -s "$(command -v fish)"
            echo -e "${GREEN}default shell changed to fish!${NC}"
        fi
    fi

    if ! grep -q 'starship init fish' "${FISH_CONFIG_DIR}/config.fish"; then
        echo -e "\n# initialize starship\nstarship init fish | source" >> "${FISH_CONFIG_DIR}/config.fish"
    fi
}

# check for required dependencies
missing=()
command -v curl &> /dev/null || missing+=("curl")
command -v git &> /dev/null || missing+=("git")

if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${YELLOW}installing missing dependencies: ${missing[*]}${NC}"
    sudo apt update && sudo apt install -y "${missing[@]}"
fi

# install fish shell
if ! command -v fish &> /dev/null; then
    echo -e "${GREEN}installing fish shell${NC}"
    sudo apt update && sudo apt install -y fish
else
    echo -e "${GREEN}fish is already installed${NC}"
fi

# install starship prompt
if ! command -v starship &> /dev/null; then
    echo -e "${GREEN}installing starship prompt...${NC}"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo -e "${GREEN}starship is already installed!${NC}"
fi

copy_configs
post_install

echo -e "\n${GREEN}setup complete!${NC}"
echo -e "start using fish shell by typing ${GREEN}fish${NC} in your terminal"
