!#/usr/bin/bash

echo "this script installs elvish shell and starship prompt, and installs my dotfiles."

sudo apt install elvish 
curl -sS https://starship.rs/install.sh | sh

echo "elvish and starship installed"

mkdir ~/.config/
mkdir ~/.config/elvish/
echo "eval (starship init elvish)" > ~/.config/elvish/rc.elv
cat << EOF > ~/.config/starship.toml
starship stuff here
EOF

echo "shell prompt done! run 'exec elvish' to get started!"
