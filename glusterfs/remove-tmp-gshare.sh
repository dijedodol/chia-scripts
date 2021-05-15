#!/usr/bin/expect -f
. constants.sh

set timeout -1
spawn sudo gluster volume remove-brick gv-chia 172.31.144.50:/tmp-gshare/data force
match_max 100000
expect -exact "Remove-brick force will not migrate files from the removed bricks, so they will no longer be available on the volume.\r
Do you want to continue? (y/n) "
send -- "y\r"
expect eof
