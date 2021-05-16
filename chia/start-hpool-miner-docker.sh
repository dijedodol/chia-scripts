#!/usr/bin/env bash
set -x
. constants.sh

sudo docker run --rm --name hpool-miner --user ubuntu -v "${HOME}/hpool:${HOME}/hpool" -v "${HOME}/gv-chia:${HOME}/gv-chia" -p '8444:8444' 'dijedodol/hpool-miner:latest' bash -c "cd ${HOME}/hpool; ./hpool-miner-chia"
