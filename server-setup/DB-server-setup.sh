#!/bin/bash

sudo sed -i 's/bind-address\s*=.*/bind-address = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

mysql_secure_installation <<EOF

y
$1
$1
y
y
y
y
EOF

echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;" | sudo mysql -u root -p"$1"
echo "FLUSH PRIVILEGES;" | sudo mysql -u root -p"$1"
echo "create database WordPressDB;" | sudo mysql -u root -p"$1"

ufw allow 3306
ufw allow 22

sed -i '/^bind-address/ s/^/#/' /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl restart mariadb
