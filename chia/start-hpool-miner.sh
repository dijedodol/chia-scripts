#!/usr/bin/env bash
set -ex
. constants.sh

/usr/bin/env bash
cd "${HOME}/hpool"

./hpool-chia-miner-linux-arm64 &
pid=$!
echo "${pid}" | tee "${HOME}/hpool/hpool.pid" > /dev/null
wait "$pid"
rm -f "${HOME}/hpool/hpool.pid"
