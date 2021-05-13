#!/usr/bin/env bash
set -v

apt install -y software-properties-common
add-apt-repository ppa:gluster/glusterfs-9
apt update
apt install -y glusterfs-server
