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

mkdir -p "${HOME}/gv-chia/plots"
mkdir -p "${HOME}/.chia"
dev_name='nvme1n1'
sudo mkfs -F -t ext4 "/dev/${dev_name}"
sudo mount "/dev/${dev_name}" "${HOME}/.chia"
sudo chown -R "${USER}:" "${HOME}/.chia"

fstab_count="$(grep -cF "/dev/${dev_name}" /etc/fstab)"
if [ "${fstab_count}" -gt 0 ]; then
  # update fstab, remove the same previous entry if exists
  temp_file="$(mktemp)"
  grep -vF "/dev/${dev_name}" /etc/fstab | tee "${temp_file}"
  echo "/dev/${dev_name} ${HOME}/.chia ext4 defaults,nofail 0" | tee -a "${temp_file}" > /dev/null
  sudo tee /etc/fstab < "${temp_file}" > /dev/null
  rm -f "${temp_file}"
else
  echo "/dev/${dev_name} ${HOME}/.chia ext4 defaults,nofail 0" | sudo tee -a /etc/fstab > /dev/null
fi

# chia install & setup systemd unit
chia/install.sh

# install docker to run hpool miner in isolated env
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt-cache policy docker.io
sudo apt install -y docker.io
sudo usermod -aG docker "${USER}"

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
