#!/usr/bin/env bash

cd /usr/src/5.15.57.1-microsoft-standard-WSL2

sudo make clean
sudo make mrproper

#sudo cp Microsoft/config-wsl .config

#sudo sed -i 's/CONFIG_LOCALVERSION="-microsoft-standard-WSL2"/CONFIG_LOCALVERSION="-microsoft-homebrew-WSL2"/g' .config

sudo make LOCALVERSION= KCONFIG_CONFIG=/mnt/c/WSL-Cust/0-linux-kernel/config-wsl -j $(nproc) | tee /mnt/c/WSL-Cust/0-linux-kernel/kbuild.log
