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
        eche -e "${RED}please run as root${}"
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
    local backup_path="/etc/ssh/sshd_config.bak"
    cp "$SSHD_CONFIG" "$backup_path"
    echo -e "${YELLOW}backup created: ${backup_path}${NC}"
}

get_network_info() {
    INTERFACE=$(ip route | grep default | awk '{print $5}')
    CURRENT_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}')
    SUBNET_MASK=24
}

configure_static_ip() {
    local CONFIG_FILE="/etc/dhcpcd.conf"
    local BACKUP_FILE="/etc/dhcpcd.conf.bak"
    
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "\s${GREEN}backup created at ${BACKUP_FILE}${NC}"

    echo -e "\n${YELLOW}current network configuration:${NC}"
    echo -e "interface: ${GREEN}$INTERFACE${NC}"
    echo -e "ip address: ${GREEN}$CURRENT_IP${NC}"
    echo -e "gateway: ${GREEN}$CURRENT_GATEWAY${NC}"

    echo -e "\n${YELLOW}configure static ip${NC}"
    
    while true; do
        read -rp "static ip address: " STATIC_IP
        validate_ip "$STATIC_IP" && break
        echo -e "${RED}invalid ip address format!${NC}"
    done

    while true; do
        read -rp "router/cateway [$CURRENT_GATEWAY]: " ROUTER_IP
        ROUTER_IP=${ROUTER_IP:-$CURRENT_GATEWAY}
        validate_ip "$ROUTER_IP" && break
        echo -e "${RED}invalid gateway ip!${NC}"
    done

    read -rp "DNS servers (comma separated) [1.1.1.1,8.8.8.8]: " DNS_SERVERS
    DNS_SERVERS=${DNS_SERVERS:-"1.1.1.1,8.8.8.8"}

    echo -e "\n${YELLOW}new configuration:${NC}"
    echo -e "interface: ${GREEN}$INTERFACE${NC}"
    echo -e "static IP: ${GREEN}$STATIC_IP/${SUBNET_MASK}${NC}"
    echo -e "gateway: ${GREEN}$ROUTER_IP${NC}"
    echo -e "DNS: ${GREEN}${DNS_SERVERS}${NC}"

    read -rp "apply these settings? [y/N]: " confirm
    [[ "$confirm" =~ [yY] ]] || exit 0

    # Configure dhcpcd
    echo -e "\n# static IP configuration (added by ssh-setup.sh)" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "interface $INTERFACE" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static ip_address=$STATIC_IP/$SUBNET_MASK" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static routers=$ROUTER_IP" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "static domain_name_servers=${DNS_SERVERS}" | sudo tee -a "$CONFIG_FILE" > /dev/null

    echo -e "${GREEN}configuration written to $CONFIG_FILE${NC}"
}

configure_sshd() {
    echo -e "${GREEN}configuring ssh server...${NC}"
    
    while true; do
        read -rp "enter ssh port (default 22): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        
        if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}invalid port number!${NC}"
        fi
    done

    systemctl restart sshd
    echo -e "${GREEN}ssh server configured on port $SSH_PORT${NC}"
}

configure_client() {
    echo -e "${GREEN}configuring ~/.ssh/config...${NC}"
    
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    while true; do
        read -rp "enter host alias: " host_alias
        read -rp "enter server IP: " SSH_IP
        read -rp "enter SSH port [$SSH_PORT]: " custom_port
        read -rp "enter username [$SUDO_USER]: " username
        
        validate_ip "$SSH_IP" || {
            echo -e "${RED}invalid ip address!${NC}"
            continue
        }
        
        custom_port=${custom_port:-$SSH_PORT}
        username=${username:-$SUDO_USER}
        
        cat << EOF >> "$CLIENT_CONFIG"
Host $host_alias
    HostName $SSH_IP
    Port $custom_port
    User $username
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    TCPKeepAlive yes
EOF
        
        echo -e "${YELLOW}add another server? [y/N]${NC}"
        read -r another
        [[ "$another" =~ [yY] ]] || break
    done

    chmod 600 "$CLIENT_CONFIG"
    echo -e "${GREEN}client configuration saved to ${CLIENT_CONFIG}${NC}"
}

generate_keys() {
    echo -e "${YELLOW}cenerate new ssh key? [y/N]${NC}"
    read -r generate
    if [[ "$generate" =~ [yY] ]]; then
        key_path="${CONFIG_DIR}/id_ed25519"
        ssh-keygen -t ed25519 -a 100 -f "$key_path"
        echo -e "${GREEN}public key:${NC}"
        cat "${key_path}.pub"
    fi
}

restart_networking() {
    echo -e "\n${YELLOW}restarting network services...${NC}"
    sudo systemctl restart dhcpcd
    echo -e "${GREEN}network services restarted${NC}"
    
    echo -e "\n${YELLOW}new network configuration:${NC}"
    ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
    echo -e "${YELLOW}try pinging your gateway: ${NC}"
    ping -c 4 "$ROUTER_IP"
}

check_root
backup_config
configure_sshd
configure_client
generate_keys
get_network_info
configure_static_ip
restart_networking

echo -e "\n${GREEN}ssh setup complete!${NC}"
