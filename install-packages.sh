#!/usr/bin/bash  
# raspberry pi setup script  
# component: package installer  
# description: installs system packages and tools  
# author: luna @ellipticobj  

source ./common.sh

install_packages() {  
    local packages=(  
        bash-completion btop build-essential cargo curl  
        elvish fish gh git gzip nano neofetch neovim  
        python3 rustup tig tmux  
    )  

    log warn "installing base packages..."  
    if $dry_run; then  
        log success "would install: ${packages[*]}"  
        return  
    fi  

    if sudo apt install -y --ignore-missing "${packages[@]}"; then  
        log success "base packages installed"  
    else  
        log error "failed to install base packages"  
        exit 1  
    fi  
}  

install_starship() {  
    log warn "installing starship prompt..."  
    if $dry_run; then  
        log success "would install starship"  
        return  
    fi  

    if curl -ss https://starship.rs/install.sh | sh -s -- -y >/dev/null; then  
        log success "starship installed"  
    else  
        log error "failed to install starship"  
        exit 1  
    fi  
}  

install_pyenv() {  
    log warn "installing pyenv..."  
    if $dry_run; then  
        log success "would install pyenv"  
        return  
    fi  

    if curl -fssl https://pyenv.run | bash >/dev/null; then  
        log success "pyenv installed"  
    else  
        log error "failed to install pyenv"  
        exit 1  
    fi  
}  

print_header() {
    echo -e "${BLUE}"
    echo "──────────────────────────────────────"
    echo "         package installer"
    echo "──────────────────────────────────────"
    echo -e "${NC}"
}

print_header

trap 'log error "installation interrupted"; exit 1' int term

DRY_RUN=false  
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true  

log warn "this will modify system packages"  
$DRY_RUN && log warn "dry run mode enabled"  

if ! confirm "continue with package installation?"; then  
    log warn "installation canceled"  
    exit 0  
fi  

log warn "updating package lists..."  
if ! $DRY_RUN; then  
    sudo apt update || {  
        log error "failed to update packages"  
        exit 1  
    }  
fi  

install_packages  
install_starship  
install_pyenv  

log success "package installation complete"  