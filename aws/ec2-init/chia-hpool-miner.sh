#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -x
su ubuntu

sudo apt update
sudo apt install -y git unzip jq expect

if [ -n "${aws_region}" ]; then
  echo "${aws_region}" | tee "${HOME}/aws_region"
fi

git clone 'https://github.com/dijedodol/chia-scripts.git' "${HOME}/chia-scripts"
(sudo crontab -u "${USER}" -l ; echo '0 * * * * cd "${HOME}/chia-scripts"; git fetch origin master; git checkout master; git merge origin/master') | sudo crontab -u "${USER}" -
cd "${HOME}/chia-scripts"
. constants.sh

# prepare glusterfs
glusterfs/install.sh
glusterfs/client-setup.sh
mkdir -p "${HOME}/gv-chia/plots"

# chia install
chia/install.sh

# hpool miner install & setup systemd unit
mkdir -p "${HOME}/hpool"
wget 'https://github.com/hpool-dev/chia-miner/releases/download/v1.3.0-4/HPool-Miner-chia-v1.3.0-4-linux.zip' -O "${HOME}/hpool/hpool-miner.zip"
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
scanPath: false
scanMinute: 15
debug: ""
language: en
singleThreadLoad: false
EOF

# setup hpool miner systemd unit
sudo cp -f 'systemd/unit/chia-hpool-miner.service' /etc/systemd/system/
sudo systemctl enable 'chia-hpool-miner'
sudo systemctl start 'chia-hpool-miner'

# setup node telegraf
telegraf/install.sh
