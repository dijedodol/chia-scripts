#!/usr/bin/env bash
set -v
. constants.sh

# mount gv-chia volume from glusterfs to user's home directory
mount -t glusterfs "${glusterfs_master_host}:/gv-chia" "${HOME}/gv-chia"
exit_code=$?
if [ "${exit_code}" -ne 0 ]; then
    echo "unable to mount glusterfs share: gv-chia with glusterfs_master_host: ${glusterfs_master_host}, exit-code: ${EXIT_CODE}"
    exit $exit_code
fi

# update fstab, remove the same previous entry if exists
temp_file=$(mktemp)
grep -vqF "${glusterfs_master_host}:/gv-chia" /etc/fstab | tee "${temp_file}"
echo "${glusterfs_master_host}:/gv-chia ${HOME}/gv-chia glusterfs defaults,_netdev,x-systemd.requires=glusterd.service,x-systemd.automount 0 0" | tee -a "${temp_file}" > /dev/null
tee /etc/fstab < "${temp_file}" > /dev/null
rm -f "${temp_file}"
