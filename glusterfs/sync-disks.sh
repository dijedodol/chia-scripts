#!/usr/bin/env bash
set -x

glusterfs/mount-disks.sh

my_ip="$(hostname -I | xargs echo -n)"
lsblk --json | jq -c '.blockdevices[] | select(.mountpoint != null) | select(.mountpoint|test("/gshare/.+")) | .name' | jq -r | while read -r dev_name; do
  gv_brick_count=$(sudo gluster volume status gv-chia | grep -F "$my_ip" | grep -cF "$dev_name")
  if [ "${gv_brick_count}" -eq 0 ]; then
    sudo gluster volume add-brick gv-chia "${my_ip}:/gshare/${dev_name}/data" force
    touch "${HOME}/gluster_gv_chia_need_rebalance"
  fi
done
if [ -f "${HOME}/gluster_gv_chia_need_rebalance" ]; then
  rm -f "${HOME}/gluster_gv_chia_need_rebalance"
  sudo gluster volume rebalance gv-chia fix-layout start
fi
