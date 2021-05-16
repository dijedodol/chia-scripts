#!/usr/bin/env bash
set -x
. constants.sh

sudo docker run --rm --name telegraf-pool -p '18080:18080' -p '9273:9273' --rm 'dijedodol/telegraf-pool:latest'
