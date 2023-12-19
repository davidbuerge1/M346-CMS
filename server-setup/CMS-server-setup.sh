#!/bin/bash

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt update -y
apt-get install docker-ce docker-ce-cli containerd.io -y
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cd WordPressCMS
cd docker
sed -i "s/<DB-Host>/$1/g" docker-compose.yml
sed -i "s/<DB-User>/root/g" docker-compose.yml
sed -i "s/<DB-Password>/$2/g" docker-compose.yml
sed -i "s/<DB-Name>/$3/g" docker-compose.yml

docker compose up -d


