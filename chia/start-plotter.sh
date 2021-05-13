#!/usr/bin/env bash
set -v
. constants.sh

suffix="$1"
run_type="$2"

# setup working directory
if [ -z "${suffix}" ]; then
  curr_date=$(date '+%Y%m%d%H%M%S')
  rand_guid=$(uuidgen)
  suffix="${curr_date}-${rand_guid}"
fi
plots_tmp_dir="${HOME}/plots-tmp/${suffix}"
mkdir -p "${plots_tmp_dir}"

fn_start_plotter_with_file() {
  bash -c 'chia plots create -r 4 -f '"${chia_farmer_public_key}"' -p '"${chia_pool_public_key}"' -t '"${plots_tmp_dir}"' -d '"${HOME}/gv-chia/plots"' -e' &
  pid=$!
  echo "${plots_tmp_dir}" | tee "${plots_tmp_dir}.pid" > /dev/null
  wait "$pid"
  rm -f "${plots_tmp_dir}.pid"
}

# start chia plotter, on systemd, we won't loop and rely on systemd restart behavior
. "${HOME}/chia-blockchain/activate"

if [ "systemd" = "${run_type}" ]; then
  fn_start_plotter_with_file
else
  touch "${plots_tmp_dir}.loop"
  while [ -f "${plots_tmp_dir}.loop" ]; do
    fn_start_plotter_with_file
  done
fi

rm -rf "${plots_tmp_dir}"
