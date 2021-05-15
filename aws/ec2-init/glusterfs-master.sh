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

# prepare ssh for inter glusterfs server comm
tee -a "${HOME}/.ssh/config" > /dev/null <<EOF
Host *
    StrictHostKeyChecking no
EOF
tee -a "${HOME}/.ssh/authorized_keys" > /dev/null < ssh-keys/glusterfs/id_rsa.pub
cp -f ssh-keys/glusterfs/id_rsa "${HOME}/.ssh/id_rsa"
chmod 600 "${HOME}/.ssh/config" "${HOME}/.ssh/authorized_keys"
chmod 400 "${HOME}/.ssh/id_rsa"

glusterfs/install.sh
sudo systemctl enable glusterd
sudo systemctl start glusterd
sudo systemctl status glusterd
glusterfs/mount-disks.sh

sudo hostnamectl set-hostname glusterfs-master

# wait for brick disk(s) to be available
gshare_count="$(ls -l /gshare/* | wc -l)"
lsblk_count="$(lsblk --json | jq -c '.blockdevices[] | select(.mountpoint == null and .type == "disk" and .children == null) | .name' | jq -r | wc -l)"
while [ "${gshare_count}" -eq 0 ] || [ "${gshare_count}" -lt "${lsblk_count}" ]; do
  echo "awaiting brick(s) to be available at /gshare/*, gshare_count: ${gshare_count}, lsblk_count: ${lsblk_count}"
  sleep 5s
  glusterfs/mount-disks.sh
  gshare_count="$(ls -l /gshare/* | wc -l)"
  lsblk_count="$(lsblk --json | jq -c '.blockdevices[] | select(.mountpoint == null and .type == "disk" and .children == null) | .name' | jq -r | wc -l)"
done

# start creating volume and add bricks
volume_created='false'
for gshare_dir in /gshare/*; do
  sleep 1s
  if [ "${volume_created}" = 'true' ]; then
    sudo gluster volume add-brick gv-chia "${glusterfs_master_host}:${gshare_dir}/data" force
  else
    sudo gluster volume create gv-chia "${glusterfs_master_host}:${gshare_dir}/data" force
    sudo gluster volume set gv-chia storage.owner-uid 1000
    sudo gluster volume set gv-chia storage.owner-gid 1000
    sudo gluster volume start gv-chia
    volume_created='true'
  fi
done

(sudo crontab -u "${USER}" -l ; echo '* * * * * cd "${HOME}/chia-scripts"; glusterfs/sync-disks.sh') | sudo crontab -u "${USER}" -
