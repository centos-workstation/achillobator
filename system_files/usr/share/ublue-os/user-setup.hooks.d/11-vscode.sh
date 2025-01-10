#!/usr/bin/bash

# Setup VSCode
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-azuretools.vscode-docker

if test ! -e "$HOME"/.config/Code/User/settings.json; then
    mkdir -p "$HOME"/.config/Code/User
    cp -f /etc/skel/.config/Code/User/settings.json "$HOME"/.config/Code/User/settings.json
fi