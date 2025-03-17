!#/usr/bin/bash

echo "this script will set up vim with vim-plug."

echo "checking if neovim is installed..."

sudo apt install neovim -y

echo "neovim installed"

echo "installing vim-plug"
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

mkdir ~/.config/nvim/

echo -e "call plug#begin()\n\nPlug 'tpope/vim-sensible'\nPlug 'wakatime/vim-wakatime'\n\ncall plug#end()" > ~/.config/nvim/init.vim

echo "done!"
echo "run :PlugInstall in nvim to install extensions."
