#!/usr/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SSH_PORT=""
SSH_IP=""
CONFIG_DIR="${HOME}/.ssh"
SSHD_CONFIG="/etc/ssh/sshd_config"
CLIENT_CONFIG="${CONFIG_DIR}/config"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}please run as root${NC}"
        exit 1
    fi
}

validate_ip() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ip_parts <<< "$ip"
        [[ ${ip_parts[0]} -le 255 && ${ip_parts[1]} -le 255 && \
           ${ip_parts[2]} -le 255 && ${ip_parts[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

backup_config() {
    local backup_path="/etc/ssh/sshd_config.bak-$(date +%s)"
    sudo cp "$SSHD_CONFIG" "$backup_path"
    echo -e "${YELLOW}backup created at ${backup_path}${NC}"
}

get_network_info() {
    INTERFACE=$(ip route | grep default | awk '{print $5}' || echo "eth0")
    CURRENT_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "127.0.0.1")
    CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' || echo "192.168.1.1")
    SUBNET_MASK=24
}

configure_static_ip() {
    local CONFIG_FILE="/etc/dhcpcd.conf"
    local BACKUP_FILE="/etc/dhcpcd.conf.bak-$(date +%s)"
    
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "\n${GREEN}backup created at ${BACKUP_FILE}${NC}"

    echo -e "\n${YELLOW}current configuration:${NC}"
    echo -e "interface: ${GREEN}$INTERFACE${NC}"
    echo -e "IP address: ${GREEN}$CURRENT_IP${NC}"
    echo -e "gateway: ${GREEN}$CURRENT_GATEWAY${NC}"

    echo -e "\n${YELLOW}configure static IP${NC}"
    
    while true; do
        read -rp "static IP address: " STATIC_IP
        validate_ip "$STATIC_IP" && break
        echo -e "${RED}invalid IP address format.${NC}"
    done

    while true; do
        read -rp "router/gateway [$CURRENT_GATEWAY]: " ROUTER_IP
        ROUTER_IP=${ROUTER_IP:-$CURRENT_GATEWAY}
        validate_ip "$ROUTER_IP" && break
        echo -e "${RED}invalid gateway IP.${NC}"
    done

    read -rp "DNS servers (comma separated) [1.1.1.1,8.8.8.8]: " DNS_SERVERS
    DNS_SERVERS=${DNS_SERVERS:-"1.1.1.1,8.8.8.8"}

    echo -e "\n${YELLOW}new configuration:${NC}"
    echo -e "interface: ${GREEN}$INTERFACE${NC}"
    echo -e "static IP: ${GREEN}$STATIC_IP/${SUBNET_MASK}${NC}"
    echo -e "gateway: ${GREEN}$ROUTER_IP${NC}"
    echo -e "DNS: ${GREEN}${DNS_SERVERS//,/, }${NC}"

    read -rp "apply? [y/N]: " confirm
    [[ "$confirm" =~ [yY] ]] || exit 0

    sudo sed -i "/# static IP configuration (added by ssh-setup.sh)/,/static domain_name_servers/d" "$CONFIG_FILE"

    echo -e "\n# static IP configuration (added by ssh-setup.sh)" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "interface $INTERFACE" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static ip_address=$STATIC_IP/$SUBNET_MASK" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static routers=$ROUTER_IP" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static domain_name_servers=${DNS_SERVERS}" | sudo tee -a "$CONFIG_FILE" > /dev/null

    echo -e "${GREEN}configuration written to $CONFIG_FILE${NC}"
}

configure_sshd() {
    echo -e "${GREEN}configuring SSH server...${NC}"
    
    while true; do
        read -rp "enter SSH port (22): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        
        if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}invalid port number.${NC}"
        fi
    done

    sudo sed -i "s/^#*Port .*/Port $SSH_PORT/" "$SSHD_CONFIG"
    sudo sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG"
    sudo sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" "$SSHD_CONFIG"

    if command -v ufw &> /dev/null; then
        sudo ufw allow "$SSH_PORT"/tcp
        echo -e "${GREEN}Firewall rule added for port $SSH_PORT${NC}"
    fi

    sudo systemctl restart sshd
    echo -e "${GREEN}SSH server configured on port $SSH_PORT${NC}"
}

configure_client() {
    echo -e "${GREEN}configuring SSH client (.ssh/config)...${NC}"
    
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    while true; do
        read -rp "enter host alias: " host_alias
        read -rp "enter server IP: " SSH_IP
        read -rp "enter SSH port [$SSH_PORT]: " custom_port
        read -rp "enter username [$(whoami)]: " username
        read -rp "enter ssh key file [~/.ssh/id_ed25519.pub]: " sshfile
        
        validate_ip "$SSH_IP" || {
            echo -e "${RED}invalid IP address!${NC}"
            continue
        }
        
        custom_port=${custom_port:-$SSH_PORT}
        username=${username:-$(whoami)}
        sshfile=${sshfile:-"~/.ssh/id_ed25519.pub"}
        
        if grep -q "Host $host_alias" "$CLIENT_CONFIG"; then
            echo -e "${YELLOW}host alias '$host_alias' already exists!${NC}"
            continue
        fi

        cat << EOF | sudo tee -a "$CLIENT_CONFIG" > /dev/null
Host $host_alias
    HostName $SSH_IP
    Port $custom_port
    User $username
    IdentityFile $sshfile
    ServerAliveInterval 60
    TCPKeepAlive yes
EOF
        
        echo -e "${YELLOW}add another server? [y/N]${NC}"
        read -r another
        [[ "$another" =~ [yY] ]] || break
    done

    sudo chmod 600 "$CLIENT_CONFIG"
    echo -e "${GREEN}configuration saved to ${CLIENT_CONFIG}${NC}"
}

generate_keys() {
    echo -e "${YELLOW}generate new SSH key pair? [y/N]${NC}"
    read -r generate
    if [[ "$generate" =~ [yY] ]]; then
        echo 
        read -rp "ssh key file name (id_ed25519)" keyfile
        keyfile=${keyfile:-"id_ed25519"}
        key_path="${CONFIG_DIR}/id_ed25519"
        ssh-keygen -t ed25519 -a 100 -f "$key_path"
        echo -e "${GREEN}Public key:${NC}"
        cat "${key_path}.pub"
        echo -e "\n${YELLOW}add this key to your remote servers:${NC}"
        echo "ssh-copy-id -i ${key_path}.pub user@host"
    fi
}

restart_networking() {
    echo -e "\n${YELLOW}restarting network services...${NC}"
    sudo systemctl restart dhcpcd
    sleep 2
    echo -e "${GREEN}network services restarted${NC}"
    
    echo -e "\n${YELLOW}new network configuration:${NC}"
    ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "no IP address found"
    echo -e "${YELLOW}testing gateway connectivity:${NC}"
    ping -c 4 "$ROUTER_IP" || echo "Ping failed"
}

main() {
    check_root
    get_network_info
    backup_config
    configure_static_ip
    restart_networking
    configure_sshd
    read -rp "set up .ssh/config file? [y/N] " configclient
    if [[ configclient =~ [Yy] ]]; then
        configure_client
    fi
    generate_keys

    echo -e "\n${GREEN}SSH setup complete!${NC}"
    echo -e "connect using: ${YELLOW}ssh <host-alias>${NC}"
    echo -e "static IP: ${YELLOW}$STATIC_IP${NC}"
    echo -e "SSH port: ${YELLOW}$SSH_PORT${NC}"
}

main
