#!/usr/bin/env bash
set -v

expected_fs='xfs'

mount_and_update_fstab() {
  local dev_name="$1"
  local mount_point="$2"

  sudo mount "/dev/${dev_name}" "${mount_point}"
  fstab_count=$(grep -vF "/dev/${dev_name}" /etc/fstab)
  if [ "${fstab_count}" -gt 0 ]; then
    # update fstab, remove the same previous entry if exists
    temp_file=$(mktemp)
    grep -vF "/dev/${dev_name}" /etc/fstab | tee "${temp_file}"
    echo "/dev/${dev_name} ${mount_point} ${expected_fs} defaults,nofail 0" | tee -a "${temp_file}" > /dev/null
    sudo tee /etc/fstab < "${temp_file}" > /dev/null
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
  blkid_exit_code="$?"
  if [ "$blkid_exit_code" -ne 0 ]; then
    echo "ignoring block_device: ${dev_name}, blkid returned exit_code: ${blkid_exit_code}"
  else
    if [ "${fs}" = "${expected_fs}" ]; then
      mount_and_update_fstab "${dev_name}" "/gshare/${dev_name}"
    else
      echo "formatting block_device: ${dev_name}, unexpected filesystem: ${fs}"
      mkfs -t "${expected_fs}" "/dev/${dev_name}"
      mount_and_update_fstab "${dev_name}" "/gshare/${dev_name}"
    fi
  fi

  sudo mkdir -p "/gshare/${dev_name}/data"
done
