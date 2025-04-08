#!/usr/bin/bash
# raspberry pi setup script
# component: ssh configuration
# description: configures ssh server and client
# author: luna @ellipticobj

source ./common.sh

SSHD_CONFIG="/etc/ssh/sshd_config"
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
    log warn "configuring ssh server... (/etc/ssh/sshd_config)"

    # Backup the original config
    if [ -f "$SSHD_CONFIG" ]; then
        log warn "backing up original sshd_config"
        sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
    fi

    while :; do
        read -rp "enter ssh port [22]: " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -le 65535 ] && break
        log error "invalid port number"
    done

    log warn "modifying ssh server configuration"

    sudo sed -i "s/^#*Port .*/Port $SSH_PORT/" "$SSHD_CONFIG" 2>/dev/null || sudo sh -c "echo 'Port $SSH_PORT' >> $SSHD_CONFIG"
    sudo sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG" 2>/dev/null || sudo sh -c "echo 'PermitRootLogin no' >> $SSHD_CONFIG"
    sudo sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" "$SSHD_CONFIG" 2>/dev/null || sudo sh -c "echo 'PasswordAuthentication no' >> $SSHD_CONFIG"

    # set proper permissions
    sudo chmod 644 "$SSHD_CONFIG"

    # restart the SSH service
    log warn "restarting ssh service"
    sudo systemctl restart sshd

    # configure firewall if available and user wants to
    if command -v ufw >/dev/null; then
        if confirm "configure firewall for SSH?"; then
            log warn "configuring firewall for port $SSH_PORT"
            sudo ufw allow "$SSH_PORT"/tcp
            log success "firewall rule added for port $SSH_PORT"

            # check if firewall is active
            if ! sudo ufw status | grep -q "Status: active"; then
                log warn "firewall rule added but firewall is not active"
                log warn "to enable the firewall, run: sudo ufw enable"
            fi
        else
            log warn "skipping firewall configuration"
        fi
    fi

    log success "ssh server configured on port $SSH_PORT"
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
    log warn "ufw (Uncomplicated Firewall) is not installed"
    if confirm "Do you want to install ufw for firewall protection?"; then
        log warn "installing ufw..."
        sudo apt-get update && sudo apt-get install -y ufw
        log success "ufw installed"
    else
        log warn "skipping firewall installation - some security features will be unavailable"
    fi
fi

# No need to check for sudo access early - we'll use sudo for specific commands

generate_ssh_key
configure_sshd
configure_client

log success "ssh setup complete"
echo -e "connect using: ${GREEN}ssh <host-alias>${NC}"