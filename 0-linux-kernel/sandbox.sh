#!/usr/bin/env bash

cd /home/xxxx/kernel

make clean
make mrproper

cp Microsoft/config-wsl .config

sed -i 's/CONFIG_LOCALVERSION="-microsoft-standard-WSL2"/CONFIG_LOCALVERSION="-microsoft-homebrew-WSL2"/g' .config

make -j $(nproc)