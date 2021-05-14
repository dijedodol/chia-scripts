#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -v

apt update
apt install -y git jq
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
glusterfs/mount-disks.sh

systemctl enable glusterd
systemctl start glusterd
systemctl status glusterd

sudo hostnamectl set-hostname glusterfs-master

volume_created='false'
for dev_name in /gshare/*; do
  if [ "${volume_created}" = 'true' ]; then
    sudo gluster volume add-brick gv-chia "${glusterfs_master_host}:/gshare/${dev_name}/data" force
  else
    sudo gluster volume create gv-chia "${glusterfs_master_host}:/gshare/${dev_name}/data" force
    volume_created=true
  fi
done

if [ "${volume_created}" = 'true' ]; then
  sudo gluster volume set gv-chia storage.owner-uid 1000
  sudo gluster volume set gv-chia storage.owner-gid 1000
  sudo gluster volume start gv-chia
else
  echo "gv-chia volume creation failed"
  exit 1
fi
