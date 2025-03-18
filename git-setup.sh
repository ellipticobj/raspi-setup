#!/usr/bin/bash  
# raspberry pi setup script  
# component: git configuration  
# description: configures git, gh, and ssh signing  
# author: luna @ellipticobj 

source ./common.sh

validate_email() {  
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]  
}  

validate_signingkey() {  
    [[ -f "$1" ]] && ssh-keygen -l -f "$1" &>/dev/null  
}  

print_header() {
    echo -e "${BLUE}"
    echo "──────────────────────────────────────"
    echo "             git setup"
    echo "──────────────────────────────────────"
    echo -e "${NC}"
}

print_header

check_deps git tig gh || {  
    log error "missing dependencies - run install-packages.sh first"  
    exit 1  
}  

log warn "configuring git..."  
while :; do  
    read -rep "enter your email: " USER_EMAIL  
    read -rep "enter your name : " USER_NAME  
    echo  

    if validate_email "$USER_EMAIL" && [[ -n "$USER_NAME" ]]; then  
        log success "email: ${USER_EMAIL}"  
        log success "name: ${USER_NAME}"  
        confirm "are these details correct?" && break  
    else  
        [[ -z "$USER_NAME" ]] && log error "name cannot be empty"  
        ! validate_email "$USER_EMAIL" && log error "invalid email format"  
    fi  
done  

git config --global user.email "$USER_EMAIL"  
git config --global user.name "$USER_NAME"  
git config --global init.defaultBranch main  
git config --global pull.rebase false  
git config --global --add safe.directory '*'  
log success "git identity configured"  

if confirm "set up ssh commit signing?"; then  
    while :; do  
        read -rp "enter path to signing key [~/.ssh/id_ed25519]: " SIGNING_KEY_PATH  
        SIGNING_KEY_PATH=${SIGNING_KEY_PATH:-~/.ssh/id_ed25519}  
        SIGNING_KEY_PATH="${SIGNING_KEY_PATH/#\~/$HOME}"  

        if validate_signingkey "$SIGNING_KEY_PATH"; then  
            git config --global gpg.format ssh  
            git config --global user.signingkey "$SIGNING_KEY_PATH"  
            log success "ssh signing configured with ${SIGNING_KEY_PATH}"  
            break  
        else  
            log error "invalid ssh key file"  
        fi  
    done  
fi  

log success "git setup complete"  