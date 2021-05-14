#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -ex
. constants.sh

suffix="$1"
if [ -z "${suffix}" ]; then
  echo "suffix is missing"
  exit 1
fi

plots_tmp_dir="${HOME}/plots-tmp/${suffix}"
rm -f "${plots_tmp_dir}.loop"
kill "$(cat "${plots_tmp_dir}.pid")"
