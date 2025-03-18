#!/usr/bin/bash

echo "this script installs default packages."

echo "updating..."
sudo apt update
sudo apt full-upgrade -y

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
echo "installed apt packages"
echo
echo "installing starship prompt"
curl -sS https://starship.rs/install.sh | sh

curl -fsSL https://pyenv.run | bash

echo "packages installed"

