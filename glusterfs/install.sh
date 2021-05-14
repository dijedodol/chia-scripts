#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -ex

sudo apt install -y software-properties-common
sudo add-apt-repository ppa:gluster/glusterfs-9
sudo apt update
sudo apt install -y glusterfs-server
