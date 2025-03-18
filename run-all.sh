#!/usr/bin/bash
# raspberry pi setup script  
# component: main script  
# description: runs everything  
# author: luna @ellipticobj 

source ./common.sh

log info "starting full system setup"
declare -a STEPS=(
    "install-packages.sh:package installation"
    "shell-setup.sh:shell configuration"
    "ide-setup.sh:ide setup"
    "git-setup.sh:git configuration"
    "ssh-setup.sh:ssh setup"
)

for step in "${STEPS[@]}"; do
    script=${step%%:*}
    description=${step#*:}
    
    log warn "stage: ${description}"
    if [[ "$script" == "ssh-setup.sh" ]]; then
        sudo ./$script --non-interactive || {
            log error "failed at ${description}"
            exit 1
        }
    else
        ./$script --non-interactive || {
            log error "failed at ${description}"
            exit 1
        }
    fi
    log success "completed ${description}"
done

log success "full setup complete"
echo "time: $(date +%T)"