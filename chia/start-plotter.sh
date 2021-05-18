#!/usr/bin/env bash
set -x
. constants.sh

suffix="$1"

if [ -f "${HOME}/chia_plotter_env.sh" ]; then
  . "${HOME}/chia_plotter_env.sh"
fi

if [ -z "${number_of_threads}" ]; then
  number_of_threads="$(nproc)"
fi

# setup working directory
if [ -z "${suffix}" ]; then
  curr_date="$(date '+%Y%m%d%H%M%S')"
  rand_guid="$(uuidgen)"
  suffix="${curr_date}-${rand_guid}"
fi
plots_tmp_dir="${HOME}/plots-tmp/${suffix}"
mkdir -p "${plots_tmp_dir}"

# loop whenever done plotting, unless we were told to stop
. "${HOME}/chia-blockchain/activate"
touch "${plots_tmp_dir}.loop"
while [ -f "${plots_tmp_dir}.loop" ]; do
  bash -c 'chia plots create -r '"'""${number_of_threads}""'"' -f '"'""${chia_farmer_public_key}""'"' -p '"'""${chia_pool_public_key}""'"' -t '"'""${plots_tmp_dir}""'"' -d '"'""${HOME}/gv-chia/plots""'"' -e' &
  pid=$!
  echo "$pid" | tee "${plots_tmp_dir}.pid" > /dev/null
  wait "$pid"
  rm -f "${plots_tmp_dir}.pid"
done

rm -rf "${plots_tmp_dir}"
