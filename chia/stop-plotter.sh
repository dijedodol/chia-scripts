#!/usr/bin/env bash
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
