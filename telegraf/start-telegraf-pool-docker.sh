#!/usr/bin/env bash
set -x
. constants.sh

sudo docker run --rm --log-driver json-file --log-opt max-size=10m --log-opt max-file=5 --name telegraf-pool -p '18080:18080' -p '9273:9273' --rm 'dijedodol/telegraf-pool:latest'
