#!/usr/bin/env bash
set -ex
. constants.sh

kill "$(cat "${HOME}/hpool/hpool.pid")"
