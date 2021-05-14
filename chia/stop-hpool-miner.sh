#!/usr/bin/env bash
set -x
. constants.sh

kill "$(cat "${HOME}/hpool/hpool.pid")"
