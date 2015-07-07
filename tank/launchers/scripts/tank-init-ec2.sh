#!/bin/bash

app_version=$1

curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get -y --force-yes install nodejs
mkdir /var/app
aws s3 cp s3://synccloud-deployments/synccloud-realtime/${app_version}.zip /tmp
unzip /tmp/${app_version}.zip var/app
