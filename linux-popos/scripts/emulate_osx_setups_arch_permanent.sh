#!/bin/bash
# For Wayland on Arch
sudo pacman -S wl-clipboard
echo "alias pbcopy='wl-copy'" >> ~/.zshrc
echo "alias pbpaste='wl-paste'" >> ~/.zshrc
