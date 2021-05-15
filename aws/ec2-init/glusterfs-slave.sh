#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -x

sudo apt update
sudo apt install -y git unzip jq

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
glusterfs/mount-disks.sh

sudo systemctl enable glusterd
sudo systemctl start glusterd
sudo systemctl status glusterd

(sudo crontab -u "${USER}" -l ; echo '* * * * * cd "${HOME}/chia-scripts"; glusterfs/mount-disks.sh cron') | sudo crontab -u "${USER}" -

# instruct master to probe and add me as gv-chia bricks
# user xargs to remove extra whitespace produced by hostname -I
ssh "${glusterfs_master_host}" sudo gluster peer probe "$(hostname -I | xargs echo -n)"
for gshare_dir in /gshare/*; do
  ssh "${glusterfs_master_host}" sudo gluster volume add-brick gv-chia "$(hostname -I | xargs echo -n):${gshare_dir}/data" force
done
