#!/usr/bin/bash

echo "this script sets up fish shell and starship prompt"

sudo apt update && sudo apt install fish

curl -sS https://starship.rs/install.sh | sh

echo "installed"

echo "copying config files..."
cp ./config-files/dotconfig/fish/config.fish ~/.config/fish/config.fish
cp ./config-files/dotconfig/starship.toml ~/.config/starship.toml
echo "done"


