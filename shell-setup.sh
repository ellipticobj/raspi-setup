#!/usr/bin/bash  
# raspberry pi setup script  
# component: shell configuration  
# description: sets up fish shell and starship prompt  
# author: luna @ellipticobj

source ./common.sh

FISH_CONFIG_SOURCE="./config-files/dotconfig/fish/config.fish"  
STARSHIP_CONFIG_SOURCE="./config-files/dotconfig/starship.toml"  
FISH_CONFIG_DIR="${HOME}/.config/fish"  
STARSHIP_CONFIG_DIR="${HOME}/.config"  

backup_config() {  
    local file="$1"  
    if [[ -f "$file" ]]; then  
        local backup="${file}.bak-$(date +%s)"  
        log warn "backing up existing config: ${file} -> ${backup}"  
        cp "$file" "$backup"  
    fi  
}  

copy_configs() {  
    mkdir -p "${FISH_CONFIG_DIR}" "${STARSHIP_CONFIG_DIR}"  

    if [[ -f "$FISH_CONFIG_SOURCE" ]]; then  
        backup_config "${FISH_CONFIG_DIR}/config.fish"  
        cp -v "$FISH_CONFIG_SOURCE" "${FISH_CONFIG_DIR}/config.fish"  
        log success "fish config copied"  
    else  
        log error "fish config file not found at ${FISH_CONFIG_SOURCE}"  
        exit 1  
    fi  

    if [[ -f "$STARSHIP_CONFIG_SOURCE" ]]; then  
        backup_config "${STARSHIP_CONFIG_DIR}/starship.toml"  
        cp -v "$STARSHIP_CONFIG_SOURCE" "${STARSHIP_CONFIG_DIR}/starship.toml"  
        log success "starship config copied"  
    else  
        log error "starship config file not found at ${STARSHIP_CONFIG_SOURCE}"  
        exit 1  
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

copy_configs  
post_install  
log success "shell setup complete"  
echo -e "start using fish shell by typing ${green}fish${nc} in your terminal"  