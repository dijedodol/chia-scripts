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

# format & mount the local nvme ssd from i3 aws ec instance
# prepare raid0 if necessary
disks_temp_file="$(mktemp)"
lsblk --json | jq -c '.blockdevices[] | select(.mountpoint == null and .type == "disk" and .children == null) | .name' | jq -r | while read -r dev_name; do
  echo "/dev/${dev_name}" | tee -a "${disks_temp_file}" > /dev/null
done
disks_size="$(wc -l < "${disks_temp_file}")"
if [ "${disks_size}" -gt 1 ]; then
  # create raid0 with name md0 and use that as our plots-tmp storage
  plots_tmp_dev_name='md0'
  sort < "${disks_temp_file}" | xargs -n "${disks_size}" sudo mdadm --create --verbose /dev/"${plots_tmp_dev_name}" --level raid0 --raid-devices="${disks_size}"
else
  # no need to raid0 since there is only 1 disk, use it directly for plots-tmp storage
  plots_tmp_dev_name="$(sort < "${disks_temp_file}" | head -n 1)"
fi
rm -f "${disks_temp_file}"

# mount the local nvme ssd, either from raid0 or directly from the device
mkdir -p "${HOME}/plots-tmp"
sudo parted /dev/"${plots_tmp_dev_name}" mktable gpt
sudo mkfs -F -t ext4 /dev/"${plots_tmp_dev_name}"
sudo mount /dev/"${plots_tmp_dev_name}" "${HOME}/plots-tmp"
sudo chown -R "${USER}:" "${HOME}/plots-tmp"

# register in fstab entry
fstab_count="$(grep -cF "/dev/${dev_name}" /etc/fstab)"
if [ "${fstab_count}" -gt 0 ]; then
  # update fstab, remove the same previous entry if exists
  temp_file="$(mktemp)"
  grep -vF "/dev/${plots_tmp_dev_name}" /etc/fstab | tee "${temp_file}"
  echo "/dev/${plots_tmp_dev_name} ${HOME}/plots-tmp ext4 defaults,nofail 0" | tee -a "${temp_file}" > /dev/null
  sudo tee /etc/fstab < "${temp_file}" > /dev/null
  rm -f "${temp_file}"
else
  echo "/dev/${plots_tmp_dev_name} ${HOME}/plots-tmp ext4 defaults,nofail 0" | sudo tee -a /etc/fstab > /dev/null
fi

# chia install & setup systemd unit
chia/install.sh

# setup node telegraf
telegraf/install.sh

if [ -n "${chia_plotter_size}" ] && [ "${chia_plotter_size}" -eq "${chia_plotter_size}" ]; then
  echo "using chia_plotter_size: ${chia_plotter_size}"
else
  chia_plotter_size='2'
fi
echo "${chia_plotter_size}" | tee "${HOME}/chia_plotter_size"

sudo cp -f 'systemd/unit/chia-plotter@.service' /etc/systemd/system/
x=${chia_plotter_size}
while [ "$x" -gt 0 ];
do
  sudo systemctl enable "chia-plotter@${x}"
  sudo systemctl start "chia-plotter@${x}"
  x=$(("$x"-1))
done
