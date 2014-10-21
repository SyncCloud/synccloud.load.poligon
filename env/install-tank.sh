#!/bin/bash

echo "deb http://ppa.launchpad.net/yandex-load/main/ubuntu precise main" >> /etc/apt/sources.list
echo "deb-src http://ppa.launchpad.net/yandex-load/main/ubuntu precise main" >> /etc/apt/sources.list
apt-get update -y
apt-get install -y --force-yes yandex-load-tank-base