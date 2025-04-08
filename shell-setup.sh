#!/usr/bin/bash
# raspberry pi setup script
# component: shell configuration
# description: sets up fish shell and starship prompt
# author: luna @ellipticobj

source ./common.sh

GITHUB_RAW_URL="https://raw.githubusercontent.com/ellipticobj/dotfiles"
GITHUB_BRANCH="main"
STARSHIP_CONFIG_URL="${GITHUB_RAW_URL}/${GITHUB_BRANCH}/starship/.config/starship.toml"
FISH_CONFIG_DIR="${HOME}/.config/fish"
STARSHIP_CONFIG_DIR="${HOME}/.config"
TEMP_DIR="$(mktemp -d)"
ORIGINAL_DIR="$(pwd)"

cleanup() {
    cd "$ORIGINAL_DIR" || log error "Failed to return to original directory"
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log warn "Cleaned up temporary files"
    fi
}

# set up trap to ensure cleanup happens even if script fails
trap cleanup EXIT

backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak-$(date +%s)"
        log warn "backing up existing config: ${file} -> ${backup}"
        cp "$file" "$backup"
    fi
}

download_configs() {
    log warn "downloading configuration files from GitHub..."
    mkdir -p "${FISH_CONFIG_DIR}" "${STARSHIP_CONFIG_DIR}" "${TEMP_DIR}"

    # Download starship.toml
    log warn "downloading starship configuration..."
    if curl -sSL "${STARSHIP_CONFIG_URL}" -o "${TEMP_DIR}/starship.toml"; then
        if [[ -s "${TEMP_DIR}/starship.toml" ]]; then
            backup_config "${STARSHIP_CONFIG_DIR}/starship.toml"
            cp -v "${TEMP_DIR}/starship.toml" "${STARSHIP_CONFIG_DIR}/starship.toml"
            log success "starship config downloaded and installed"
        else
            log error "downloaded starship config file is empty"
            return 1
        fi
    else
        log error "failed to download starship config from ${STARSHIP_CONFIG_URL}"
        return 1
    fi

    # clone the repository to get fish configuration files
    log warn "downloading fish configuration..."
    if git clone --depth 1 --filter=blob:none --sparse https://github.com/ellipticobj/dotfiles.git "${TEMP_DIR}/dotfiles"; then
        # Change to the cloned repository directory
        cd "${TEMP_DIR}/dotfiles" || {
            log error "failed to change to dotfiles directory"
            return 1
        }

        git sparse-checkout set fish/.config/fish

        if [ -d "${TEMP_DIR}/dotfiles/fish/.config/fish" ]; then
            backup_config "${FISH_CONFIG_DIR}/config.fish"

            mkdir -p "${FISH_CONFIG_DIR}"

            cp -rv "${TEMP_DIR}/dotfiles/fish/.config/fish/"* "${FISH_CONFIG_DIR}/"
            log success "fish config files downloaded and installed"
        else
            log error "fish config directory not found in the repository"
            return 1
        fi

        cd "$ORIGINAL_DIR" || {
            log error "failed to return to original directory"
            return 1
        }
    else
        log error "failed to clone dotfiles repository"
        return 1
    fi
}

post_install() {
    if [[ "$SHELL" != "$(command -v fish)" ]]; then
        if confirm "set fish as default shell?"; then
            chsh -s "$(command -v fish)"
            log success "default shell changed to fish"
        fi
    fi

    if ! grep -q 'starship init fish' "${FISH_CONFIG_DIR}/config.fish"; then
        echo -e "\n# initialize starship\nstarship init fish | source" >> "${FISH_CONFIG_DIR}/config.fish"
        log success "added starship init to fish config"
    fi
}

print_header() {
    echo -e "${BLUE}"
    echo "──────────────────────────────────────"
    echo "         shell configuration"
    echo "──────────────────────────────────────"
    echo -e "${NC}"
}

[[ -z "$NON_INTERACTIVE" ]] && print_header

check_deps curl git || exit 1

if ! command -v fish >/dev/null; then
    log error "fish shell not installed - run install-packages.sh first"
    exit 1
fi

if ! command -v starship >/dev/null; then
    log error "starship not installed - run install-packages.sh first"
    exit 1
fi


log warn "this script will download shell configurations"
log warn "starship config: ${STARSHIP_CONFIG_URL}"
log warn "fish config: https://github.com/ellipticobj/dotfiles/tree/main/fish/.config/fish"

if confirm "do you want to download and install these configurations?"; then
    if download_configs; then
        post_install
        log success "shell setup complete"
        echo -e "start using fish shell by typing ${GREEN}fish${NC} in your terminal"
    else
        log error "shell setup failed"
        exit 1
    fi
else
    log warn "setup cancelled by user"
    exit 0
fi