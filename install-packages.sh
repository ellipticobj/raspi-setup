#!/usr/bin/bash  
# raspberry pi setup script  
# component: package installer  
# description: installs system packages and tools  
# author: luna @ellipticobj  

source ./common.sh

install_packages() {  
    log warn "installing base packages..."

    if sudo apt install -y --ignore-missing bash-completion btop build-essential cargo curl elvish fish gh git gzip nano neofetch neovim python3 tig tmux; then  
        log success "base packages installed"  
    else  
        log error "failed to install base packages"  
        exit 1  
    fi  
}  

install_starship() {  
    log warn "installing starship prompt..."

    if curl -ss https://starship.rs/install.sh | sh -s -- -y >/dev/null; then  
        log success "starship installed"  
    else  
        log error "failed to install starship"  
        exit 1  
    fi  
}  

install_pyenv() {  
    log warn "installing pyenv..."  

    if curl -fssl https://pyenv.run | bash >/dev/null; then  
        log success "pyenv installed"  
    else  
        log error "failed to install pyenv"  
        exit 1  
    fi  
}  

install_meower() {  
    log warn "installing meower..."  

    if curl -fsSL "https://raw.githubusercontent.com/ellipticobj/meower/refs/heads/v1/gitinstall.sh" | sh >/dev/null; then  
        log success "meower installed"  
    else  
        log error "failed to install meower"  
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

log warn "this will modify system packages"  

if ! confirm "continue with package installation?"; then  
    log warn "installation canceled"  
    exit 0  
fi  

log warn "updating package lists..."  
if ! sudo apt update; then  
    log error "failed to update packages"  
    exit 1  
fi  

install_packages  
install_starship  
install_pyenv  
install_meower  

log success "package installation complete"  