#!/usr/bin/env bash
set -x

instance_type=others
if [ -n "$1" ]; then
  instance_type="$1"
fi

wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo apt-get update && sudo apt-get install telegraf

echo "aws_region="'"'"$(cat "${HOME}/aws_region")"'"' | sudo tee -a /etc/default/telegraf
echo "user_home="'"'"${HOME}"'"' | sudo tee -a /etc/default/telegraf

sudo cp -f telegraf/conf.d/telegraf-node.conf /etc/telegraf/telegraf.conf
if [ "${instance_type}" = 'glusterfs' ]; then
  cp -f telegraf/conf.d/telegraf-node-glusterfs.conf /etc/telegraf/telegraf.d/
fi

sudo systemctl enable telegraf
sudo systemctl start telegraf
