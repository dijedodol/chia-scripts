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

# prepare hostname & ssh
sudo hostnamectl set-hostname "$(cat "${HOME}/aws_region")"
tee -a "${HOME}/.ssh/config" > /dev/null <<EOF
Host *
    StrictHostKeyChecking no
EOF
if [ -n "${ssh_id_rsa_base64}" ]; then
  echo "${ssh_id_rsa_base64}" | base64 -d | tee "${HOME}/.ssh/id_rsa" > /dev/null
fi
chmod 600 "${HOME}/.ssh/config"
chmod 400 "${HOME}/.ssh/id_rsa"

# prepare glusterfs
glusterfs/install.sh
glusterfs/client-setup.sh
mkdir -p "${HOME}/gv-chia/plots"

# format & mount the local nvme ssd from i3 aws ec instance
mkdir -p "${HOME}/plots-tmp"
sudo mkfs -t ext4 /dev/nvme0n1
sudo mount /dev/nvme0n1 "${HOME}/plots-tmp"
sudo chown -R "${USER}:" "${HOME}/plots-tmp"

fstab_count="$(grep -cF "/dev/${dev_name}" /etc/fstab)"
if [ "${fstab_count}" -gt 0 ]; then
  # update fstab, remove the same previous entry if exists
  temp_file="$(mktemp)"
  grep -vF "/dev/nvme0n1" /etc/fstab | tee "${temp_file}"
  echo "/dev/nvme0n1 ${HOME}/plots-tmp ext4 defaults,nofail 0" | tee -a "${temp_file}" > /dev/null
  sudo tee /etc/fstab < "${temp_file}" > /dev/null
  rm -f "${temp_file}"
else
  echo "/dev/nvme0n1 ${HOME}/plots-tmp ext4 defaults,nofail 0" | sudo tee -a /etc/fstab > /dev/null
fi

# chia install & setup systemd unit
chia/install.sh

sudo cp -f 'systemd/unit/chia-plotter@.service' /etc/systemd/system/
sudo systemctl enable 'chia-plotter@1'
sudo systemctl start 'chia-plotter@1'

# install docker to run hpool miner in isolated env
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt-cache policy docker.io
sudo apt install -y docker.io
sudo usermod -aG docker "${USER}"

# hpool miner install & setup systemd unit
mkdir -p "${HOME}/hpool"
wget 'https://github.com/hpool-dev/chia-miner/releases/download/v1.3.0-3/HPool-Miner-chia-v1.3.0-3-linux.zip' -O "${HOME}/hpool/hpool-miner.zip"
unzip -jo "${HOME}/hpool/hpool-miner.zip" -x .DS_Store -d "${HOME}/hpool"
rm -f "${HOME}/hpool/hpool-miner.zip"

# construct hpool config
tee "${HOME}/hpool/config.yaml" > /dev/null <<EOF
token: ""
apiKey: 3df2d2c3-d437-4f4d-83c5-e096f8ceddc8
cachePath: ""
deviceId: ""
extraParams: {}
log:
  lv: info
  path: ./log
  name: miner.log
url:
  info: ""
  submit: ""
  line: ""
scanPath: true
scanMinute: 5
debug: ""
language: en
path:
EOF
echo "- ${HOME}/gv-chia/plots" | tee -a "${HOME}/hpool/config.yaml"
echo "minerName: $(cat "${HOME}/aws_region")" | tee -a "${HOME}/hpool/config.yaml"

# prepare docker image for hpool miner
/usr/bin/env bash
cd "${HOME}/chia-scripts/chia"
sudo docker build -t 'dijedodol/hpool-miner:latest' -f 'hpool-miner-dockerfile' .
exit

# setup hpool miner systemd unit
sudo cp -f 'systemd/unit/chia-hpool-miner-docker.service' /etc/systemd/system/chia-hpool-miner.service
sudo systemctl enable 'chia-hpool-miner'
sudo systemctl start 'chia-hpool-miner'

# prepare docker image for telegraf-pool
/usr/bin/env bash
cd "${HOME}/chia-scripts/telegraf"
sudo docker build -t 'dijedodol/telegraf-pool:latest' -f 'telegraf-pool-dockerfile' .
exit

# setup telegraf-pool systemd unit
sudo cp -f 'systemd/unit/telegraf-pool-docker.service' /etc/systemd/system/telegraf-pool.service
sudo systemctl enable 'telegraf-pool'
sudo systemctl start 'telegraf-pool'

# setup node telegraf
telegraf/install.sh

# ansible
sudo apt install -y ansible

echo '[glusterfs_master]' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.50' | sudo tee -a /etc/ansible/hosts > /dev/null

echo '[glusterfs]' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.50' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.51' | sudo tee -a /etc/ansible/hosts > /dev/null

echo '[chia_ploter]' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.128.10' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.100' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.101' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.144.102' | sudo tee -a /etc/ansible/hosts > /dev/null

echo '[chia_hpool_miner]' | sudo tee -a /etc/ansible/hosts > /dev/null
echo '172.31.128.10' | sudo tee -a /etc/ansible/hosts > /dev/null
