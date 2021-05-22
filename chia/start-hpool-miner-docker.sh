#!/usr/bin/env bash
set -x
. constants.sh

sudo docker run --rm --log-driver json-file --log-opt max-size=10m --log-opt max-file=5 --name hpool-miner --user ubuntu -v "${HOME}/hpool:${HOME}/hpool" -v "${HOME}/gv-chia:${HOME}/gv-chia" 'dijedodol/hpool-miner:latest' bash -c "cd ${HOME}/hpool; ./hpool-miner-chia"
