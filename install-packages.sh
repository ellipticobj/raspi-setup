#!/usr/bin/bash

# exit on errors and prevent unset variables
set -euo pipefail

echo
echo "updating package lists..."
sudo apt update

echo
echo "performing full system upgrade..."
sudo apt full-upgrade -y

echo
echo "installing base packages..."
sudo apt install --ignore-missing -y \
    bash-completion \
    bash \
    btop \
    build-essential \
    cargo \
    curl \
    elvish \
    fish \
    gh \
    git \
    gzip \
    nano \
    neofetch \
    neovim \
    python3 \
    rustup \
    tig \
    tmux 

echo
echo "base packages installed"

echo
echo "installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null

echo
echo "installing pyenv..."
curl -fsSL https://pyenv.run | bash > /dev/null

echo
echo "package installation complete"
