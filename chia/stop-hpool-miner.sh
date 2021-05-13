#!/usr/bin/env bash
set -v
. constants.sh

kill "$(cat "${HOME}/hpool/hpool.pid")"
