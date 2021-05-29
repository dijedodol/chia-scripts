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
plots_tmp_dir="${HOME}/plots-tmp"
worker_plots_tmp_dir="${plots_tmp_dir}/${suffix}"
mkdir -p "${worker_plots_tmp_dir}"
rm -rf "${worker_plots_tmp_dir}/"*

# staggered start
touch "${worker_plots_tmp_dir}.loop"
(
  flock -x 9 || exit 1
  if [ ! -f "${plots_tmp_dir}/last_start_timestamp" ]; then
    echo '0' | tee "${plots_tmp_dir}/last_start_timestamp" > /dev/null
  fi
  last_start_timestamp=$(cat "${plots_tmp_dir}/last_start_timestamp")
  current_timestamp=$(date +%s)
  elapsed_seconds=$(("${current_timestamp}" - "${last_start_timestamp}"))
  delay_seconds='900'
  echo "elapsed_seconds: ${elapsed_seconds}"
  if [ "${elapsed_seconds}" -lt "${delay_seconds}" ]; then
    await_seconds="$(("${delay_seconds}"-"${elapsed_seconds}"))"
    echo "awaiting for ${await_seconds} seconds before starting another instance of plotter with suffix: ${suffix}"
    sleep "${await_seconds}s"
  fi
  date +%s | tee "${plots_tmp_dir}/last_start_timestamp" > /dev/null
) 9>"${plots_tmp_dir}/last_start_timestamp.lock"

# loop whenever done plotting, unless we were told to stop
. "${HOME}/chia-blockchain/activate"
while [ -f "${worker_plots_tmp_dir}.loop" ]; do
  bash -c 'chia plots create -r '"'""${number_of_threads}""'"' -f '"'""${chia_farmer_public_key}""'"' -p '"'""${chia_pool_public_key}""'"' -t '"'""${worker_plots_tmp_dir}""'"' -d '"'""${HOME}/gv-chia/plots""'"' -e' &
  pid=$!
  echo "$pid" | tee "${worker_plots_tmp_dir}.pid" > /dev/null
  wait "$pid"
  rm -f "${worker_plots_tmp_dir}.pid"
done

rm -rf "${worker_plots_tmp_dir}"
