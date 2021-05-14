#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export glusterfs_master_host='172.31.144.50'
export chia_farmer_public_key='932788a945cf47c0f1764965c9ea9a5265ca3b44e19ae8bfe1f1ece6bdf42137688b7a4e807f422779378e6b82ae76a2'
export chia_pool_public_key='affa168ed5a7fad8601cb890a9b3b111bc1a380f5758974ee79606b5e29f598b701435530e21da056ad2a4a2a4abb127'
