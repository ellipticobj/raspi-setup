#!/usr/bin/bash

# exit on errors
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}this script will set up vim with vim-plug${NC}"
echo
echo -e "${YELLOW}checking dependencies${NC}"
if ! command -v curl $> /dev/null; then
	echo "installing curl..."
	sudo apt update && sudo apt install -y curl
fi

if ! command -v nvim &> /dev/null; then
	echo "${YELLOW}installing neovim...${NC}"
	sudo apt update && sudo apt install -y neovim
else
	echo -e "${YELLOW}neovim installed!${NC}"
fi
echo
echo -e "${YELLOW}installing vim-plug${NC}"
PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [ ! -f "$PLUG_PATH" ]; then 
	curl -fLo "$PLUG_PATH" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
	echo -e "${GREEN}vim-plug is already installed${NC}"
fi

mkdir -p ~/.config/nvim
echo
CONFIG_FILE="$HOME/.config/nvim/init.vim"
if [ -f "$CONFIG_FILE" ]; then
	echo -e "${YELLOW}backing up existing init.vim to init.vim.bak${NC}"
	cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    echo
fi

echo -e "${YELLOW}creating init.vim...${NC}"
cp "./config-files/dotconfig/nvim/init.vim" "~/.config/nvim/init.vim"

echo -e "${YELLOW}installing plugins now${NC}"
nvim --headless +PlugInstall +qall
echo
echo -e "${GREEN}nvim setup complete!${NC}"

echo -e "${YELLOW}setting up pyenv...${NC}"
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
echo "pyenv init - fish | source" > ~/.config/fish/config.fish
echo
echo -e "${GREEN}setup complete!${NC}"
