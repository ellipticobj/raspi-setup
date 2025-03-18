#!/usr/bin/bash  
# raspberry pi setup script  
# component: ide configuration  
# description: sets up neovim with vim-plug and pyenv  
# author: luna @elliptcobj

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)  
source "${SCRIPT_DIR}/lib/common.sh"  

PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"  
CONFIG_FILE="${HOME}/.config/nvim/init.vim"  

check_deps curl || exit 1  

log info "ide setup"

log warn "checking dependencies..."  
if ! command -v nvim >/dev/null; then  
	log error "neovim not installed - run install-packages.sh first"  
	exit 1  
fi  

log warn "installing vim-plug..."  
if [[ ! -f "$PLUG_PATH" ]]; then  
	mkdir -p "$(dirname "$PLUG_PATH")"  
	curl -fLo "$PLUG_PATH" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim  
	log success "vim-plug installed"  
else  
	log success "vim-plug already exists"  
fi  

log warn "configuring neovim..."  
mkdir -p ~/.config/nvim  
if [[ -f "$CONFIG_FILE" ]]; then  
	backup_config "$CONFIG_FILE"  
	log warn "backed up existing init.vim"  
fi  

cp "${SCRIPT_DIR}/config-files/dotconfig/nvim/init.vim" "$CONFIG_FILE"  
log success "neovim config created"  

log warn "installing plugins..."  
nvim --headless +PlugInstall +qall  
log success "plugins installed"  

log warn "configuring pyenv..."  
if ! command -v fish >/dev/null; then  
	log error "fish shell required for pyenv setup"  
	exit 1  
fi  

fish -c "set -Ux PYENV_ROOT \$HOME/.pyenv; fish_add_path \$PYENV_ROOT/bin"  
echo "pyenv init - fish | source" >> ~/.config/fish/config.fish  
log success "pyenv configured for fish"  

log success "ide setup complete"  