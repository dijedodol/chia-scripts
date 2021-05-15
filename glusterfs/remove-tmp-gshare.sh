#!/usr/bin/expect

set timeout -1
sudo gluster volume remove-brick gv-chia "${glusterfs_master_host}:/tmp-gshare/data" force
send -- "y\r"
expect eof
