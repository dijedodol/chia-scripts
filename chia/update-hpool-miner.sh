#!/usr/bin/env bash
set -x
. constants.sh

# hpool miner install & setup systemd unit
mkdir -p "${HOME}/hpool"
wget 'https://github.com/hpool-dev/chia-miner/releases/download/v1.3.0-6/HPool-Miner-chia-v1.3.0-6-linux.zip' -O "${HOME}/hpool/hpool-miner.zip"
unzip -jo "${HOME}/hpool/hpool-miner.zip" -x .DS_Store -d "${HOME}/hpool"
rm -f "${HOME}/hpool/hpool-miner.zip"

# construct hpool config
tee "${HOME}/hpool/config.yaml" > /dev/null <<EOF
token: ""
path:
- ${HOME}/gv-chia/plots
minerName: "$(cat "${HOME}/aws_region")"
apiKey: 3df2d2c3-d437-4f4d-83c5-e096f8ceddc8
cachePath: ""
deviceId: ""
extraParams: {}
log:
  lv: info
  path: ./log/
  name: miner.log
url:
  info: ""
  submit: ""
  line: ""
scanPath: true
scanMinute: 5
debug: ""
language: en
singleThreadLoad: false
EOF

sudo systemctl restart chia-hpool-miner
