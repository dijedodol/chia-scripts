#!/usr/bin/env bash
set -x

sudo apt-get update
sudo apt-get upgrade -y

# Install Git
sudo apt install git -y

# Checkout the source and install
git clone https://github.com/Chia-Network/chia-blockchain.git -b latest --recurse-submodules "${HOME}/chia-blockchain"
cd "${HOME}/chia-blockchain"

sh install.sh

. ./activate
chia init
