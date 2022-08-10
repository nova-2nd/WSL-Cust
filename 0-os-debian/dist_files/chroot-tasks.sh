#!/bin/bash

apt-get clean
locale-gen
usermod -s /root/provision.sh root
