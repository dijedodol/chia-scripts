#!/usr/bin/env bash
set -ex

sudo apt install -y software-properties-common
sudo add-apt-repository ppa:gluster/glusterfs-9
sudo apt update
sudo apt install -y glusterfs-server
