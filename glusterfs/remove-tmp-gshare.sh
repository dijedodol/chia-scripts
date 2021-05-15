#!/usr/bin/env bash
. constants.sh

sudo gluster volume remove-brick gv-chia "${glusterfs_master_host}:/tmp-gshare/data" force
