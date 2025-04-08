#!/usr/bin/bash  
# raspberry pi setup script  
# component: common utilities  
# description: shared functions for setup scripts  
# author: luna @ellipticobj

RED='\033[0;31m'  
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'  
BLUE='\033[0;34m'  
NC='\033[0m'  

log() {  
    local level="$1"  
    shift  
    local timestamp=$(date +"%y-%m-%d %t")  
    case "$level" in  
        success) echo -e "${GREEN}[✓] $timestamp - $*${NC}" ;;  
        warn) echo -e "${YELLOW}[!] $timestamp - $*${NC}" ;;  
        error) echo -e "${RED}[x] $timestamp - $*${NC}" ;;  
        *) echo "[i] $timestamp - $*" ;;  
    esac  
}  

confirm() {  
    [[ "$NON_INTERACTIVE" == true ]] && return 0
    local prompt="$1"  
    read -rp "$prompt [y/n] " response  
    [[ "$response" =~ ^[yY] ]]  
}  

check_deps() {  
    local missing=()  
    for dep in "$@"; do  
        command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")  
    done  
    [[ ${#missing[@]} -eq 0 ]] || {  
        log error "missing dependencies: ${missing[*]}"  
        return 1  
    }  
}  