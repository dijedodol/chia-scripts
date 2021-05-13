#!/usr/bin/env bash
set -v
. constants.sh

suffix="$1"
run_type="$2"

if [ -z "${suffix}" ]; then
  echo "suffix is missing"
  exit 1
fi

if [ -z "${run_type}" ]; then
  echo "run_type is missing"
  exit 1
fi

plots_tmp_dir="${HOME}/plots-tmp/${suffix}"
if [ "systemd" != "${run_type}" ]; then
  rm -f "${plots_tmp_dir}.loop"
fi
kill "$(cat "${plots_tmp_dir}.pid")"
