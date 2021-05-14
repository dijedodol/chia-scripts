#!/usr/bin/env bash
set -x

expected_fs='xfs'
run_type='ec2-init'

if [ -z "$1" ]; then
  run_type="$1"
fi

mount_and_update_fstab() {
  local dev_name="$1"
  local mount_point="$2"

  sudo mount "/dev/${dev_name}" "${mount_point}"
  sudo mkdir -p "${mount_point}/data"

  # if it's ran by a scheduler, we wants to have the new mounted disks
  # to be added to the glusterfs array as well
  if [ "$run_type" = 'cron' ]; then
    sudo gluster volume add-brick gv-chia "$(hostname -I):${mount_point}/data" force
  fi

  fstab_count=$(grep -c "/dev/${dev_name}" /etc/fstab)
  if [ "${fstab_count}" -gt 0 ]; then
    # update fstab, remove the same previous entry if exists
    temp_file=$(mktemp)
    grep -vF "/dev/${dev_name}" /etc/fstab | tee "${temp_file}"
    echo "/dev/${dev_name} ${mount_point} ${expected_fs} defaults,nofail 0" | tee -a "${temp_file}" > /dev/null
    sudo tee /etc/fstab > /dev/null < "${temp_file}"
    rm -f "${temp_file}"
  else
    echo "/dev/${dev_name} ${mount_point} ${expected_fs} defaults,nofail 0" | sudo tee -a /etc/fstab > /dev/null
  fi
}

# mount any available disk
lsblk --json | jq -c '.blockdevices[] | select(.mountpoint == null and .type == "disk" and .children == null) | .name' | jq -r | while read -r dev_name; do
  echo "dev_name: ${dev_name}"
  sudo mkdir -p "/gshare/${dev_name}"

  fs=$(sudo blkid "/dev/${dev_name}" -o value -s TYPE)
  if [ "${fs}" = "${expected_fs}" ]; then
    mount_and_update_fstab "${dev_name}" "/gshare/${dev_name}"
  elif [ -z "$fs" ]; then
    echo "formatting block_device because there is no filesystem detected on block_device: ${dev_name}"
    sudo mkfs -t "${expected_fs}" "/dev/${dev_name}"
    mount_and_update_fstab "${dev_name}" "/gshare/${dev_name}"
  else
    echo "skipping block_device: ${dev_name}, unexpected existing filesystem: ${fs}"
  fi
done
