#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt-get update -y && apt-get upgrade -y
apt-get install -y apt-transport-https grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service
apt autoremove -y
reboot