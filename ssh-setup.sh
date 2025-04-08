#!/usr/bin/bash
# raspberry pi setup script
# component: ssh configuration
# description: configures ssh server and client
# author: luna @ellipticobj

source ./common.sh

CLIENT_CONFIG="${HOME}/.ssh/config"
CONFIG_DIR="${HOME}/.ssh"

validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] &&
    IFS='.' read -ra PARTS <<< "$ip" &&
    [[ "${PARTS[0]}" -le 255 && "${PARTS[1]}" -le 255 &&
    "${PARTS[2]}" -le 255 && "${PARTS[3]}" -le 255 ]]
}

configure_sshd() {
    log warn "creating ssh server configuration template..."
    local SSHD_CONFIG_TEMPLATE="${HOME}/sshd_config.template"

    while :; do
        read -rp "enter ssh port [22]: " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -le 65535 ] && break
        log error "invalid port number"
    done

    # Create a template file with recommended settings
    cat > "$SSHD_CONFIG_TEMPLATE" << EOF
# SSH Server Configuration Template
# Copy these settings to /etc/ssh/sshd_config

Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
EOF

    log success "ssh server configuration template created at $SSHD_CONFIG_TEMPLATE"
    log warn "To apply these settings, run the following commands as root:"
    echo -e "${YELLOW}sudo cp $SSHD_CONFIG_TEMPLATE /etc/ssh/sshd_config${NC}"
    echo -e "${YELLOW}sudo systemctl restart sshd${NC}"

    if command -v ufw >/dev/null; then
        log warn "To configure the firewall, run:"
        echo -e "${YELLOW}sudo ufw allow $SSH_PORT/tcp${NC}"
    fi
}

configure_client() {
    log warn "configuring ssh client... (~/.ssh/config)"
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    while :; do
        read -rp "enter host alias: " HOST_ALIAS
        read -rp "enter server ip: " SSH_IP
        read -rp "enter ssh port [$SSH_PORT]: " CUSTOM_PORT
        read -rp "enter username [$(whoami)]: " USERNAME
        read -rp "enter ssh key [~/.ssh/id_ed25519]: " SSH_KEY

        validate_ip "$SSH_IP" || {
            log error "invalid ip address"
            continue
        }

        CUSTOM_PORT=${CUSTOM_PORT:-$SSH_PORT}
        USERNAME=${USERNAME:-$(whoami)}
        SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519}"
        SSH_KEY="${SSH_KEY/#\~/$HOME}"

        # create the config file if it doesn't exist
        if [ ! -f "$CLIENT_CONFIG" ]; then
            touch "$CLIENT_CONFIG"
            chmod 600 "$CLIENT_CONFIG"
        fi

        if grep -q "Host $HOST_ALIAS" "$CLIENT_CONFIG" 2>/dev/null; then
            log warn "host alias '$HOST_ALIAS' already exists"
            continue
        fi

        cat << EOF >> "$CLIENT_CONFIG"
Host $HOST_ALIAS
    HostName $SSH_IP
    Port $CUSTOM_PORT
    User $USERNAME
    IdentityFile $SSH_KEY
    ServerAliveInterval 60
EOF
        log success "added host $HOST_ALIAS"

        confirm "add another server?" || break
    done

    chmod 600 "$CLIENT_CONFIG"
}

generate_ssh_key() {
    log warn "generating ssh key..."
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -q -N ""
    log success "ssh key generated at $HOME/.ssh/id_ed25519"
}

print_header() {
    echo -e "${BLUE}"
    echo "──────────────────────────────────────"
    echo "             ssh setup"
    echo "──────────────────────────────────────"
    echo -e "${NC}"
}

[[ -z "$NON_INTERACTIVE" ]] && print_header

check_deps ip awk || {
    log error "missing dependencies - run install-packages.sh first"
    exit 1
}

if ! command -v ufw >/dev/null; then
    log warn "ufw not installed - some firewall features will be unavailable"
fi

generate_ssh_key
configure_sshd
configure_client

log success "ssh setup complete"
echo -e "connect using: ${green}ssh <host-alias>${nc}"