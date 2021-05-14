#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -x

apt update
apt install -y git
su ubuntu

cd "${HOME}"
if [ -n "${aws_region}" ]; then
  echo "${aws_region}" | tee aws_region
fi

git clone 'https://github.com/dijedodol/chia-scripts.git' "${HOME}/chia-scripts"
(sudo crontab -u "${USER}" -l ; echo '0 * * * * cd "${HOME}/chia-scripts"; git fetch origin master; git checkout master; git merge origin/master') | sudo crontab -u "${USER}" -
cd "${HOME}/chia-scripts"
. constants.sh

glusterfs/install.sh
glusterfs/client-setup.sh
mkdir -p "${HOME}/gv-chia/plots"

# format & mount the local nvme ssd from i3 aws ec instance
mkdir -p "${HOME}/plots-tmp"
sudo mkfs -t ext4 /dev/nvme0n1
sudo mount /dev/nvme0n1 "${HOME}/plots-tmp"
sudo chown -R "${USER}:" "${HOME}/plots-tmp"

fstab_count="$(grep -c "/dev/${dev_name}" /etc/fstab)"
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
sudo systemctl enable 'chia-plotter@2'
sudo systemctl start 'chia-plotter@1'
sudo systemctl start 'chia-plotter@2'
