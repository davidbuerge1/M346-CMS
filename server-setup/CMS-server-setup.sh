#!/bin/bash

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt update -y
apt-get install docker-ce docker-ce-cli containerd.io -y
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#installation apache, php 
sudo apt install apache2
sudo apt install php libapache2-mod-php


# Download and extract WordPress
sudo apt install wget
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
sudo cp -a /tmp/wordpress/. /var/www/html

# Set the correct permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Configure Apache
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf
sudo sed -i 's/\/var\/www\/html/\/var\/www\/html\/wp-admin/g' /etc/apache2/sites-available/wordpress.conf
sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

cd server-setup
cd docker
sed -i "s/<DB-Host>/$1/g" docker-compose.yml
sed -i "s/<DB-User>/root/g" docker-compose.yml
sed -i "s/<DB-Password>/$2/g" docker-compose.yml
sed -i "s/<DB-Name>/$3/g" docker-compose.yml

docker compose up -d
