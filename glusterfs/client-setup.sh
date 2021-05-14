#!/usr/bin/env bash
set -x
. constants.sh

# mount gv-chia volume from glusterfs to user's home directory
mkdir -p "${HOME}/gv-chia"
sudo mount -t glusterfs "${glusterfs_master_host}:/gv-chia" "${HOME}/gv-chia"
exit_code=$?
if [ "${exit_code}" -ne 0 ]; then
    echo "unable to mount glusterfs share: gv-chia with glusterfs_master_host: ${glusterfs_master_host}, exit-code: ${exit_code}"
    exit $exit_code
fi

fstab_count="$(grep -c "${glusterfs_master_host}:/gv-chia" /etc/fstab)"
if [ "${fstab_count}" -gt 0 ]; then
  # update fstab, remove the same previous entry if exists
  temp_file=$(mktemp)
  grep -vF "${glusterfs_master_host}:/gv-chia" /etc/fstab | tee "${temp_file}"
  echo "${glusterfs_master_host}:/gv-chia ${HOME}/gv-chia glusterfs defaults,_netdev,x-systemd.requires=glusterd.service,x-systemd.automount 0 0" | tee -a "${temp_file}" > /dev/null
  sudo tee /etc/fstab > /dev/null < "${temp_file}"
  rm -f "${temp_file}"
else
  echo "${glusterfs_master_host}:/gv-chia ${HOME}/gv-chia glusterfs defaults,_netdev,x-systemd.requires=glusterd.service,x-systemd.automount 0 0" | sudo tee -a /etc/fstab > /dev/null
fi
