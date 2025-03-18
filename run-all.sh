#!/usr/bin/bash

chmod +x *.sh

./install-packages.sh
./shell-setup.sh
./ide-setup.sh
./git-setup.sh
sudo ./ssh-setup.sh

echo "done."
