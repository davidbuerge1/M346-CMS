#!/bin/bash

# erstellen der Keypairs
aws ec2 create-key-pair --key-name key_cms --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/Key_cms.pem

# erstellen der Sequirty Group
aws ec2 create-security-group --group-name sec-group --description "Webserver-EC2" > /dev/null

# ID der Security Group in die Variable sec_id schreiben
sec_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=sec-group" --query 'SecurityGroups[*].{ID:GroupId}' --output text)

# Secuirty Group autorisieren
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 3306 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol icmp --port -1 --cidr 0.0.0.0/0 


mkdir ~/ec2cmswebserver
cd ~/ec2cmswebserver
# erstellen der inital Datei und befüllen mit Inhalt
touch initial.txt
table_prefix='$table_prefix'
cat > initial.txt << END 
#!/bin/bash

# Update and install Apache web server, PHP, and MySQL
sudo yum update
sudo yum upgrade
sudo yum install wget
sudo yum update -y
sudo yum install -y httpd php mysql-server php-mbstring php-dom php-mysqli

# Start the Apache web server and MySQL
sudo service httpd start
sudo service mysqld start

# Set the Apache web server and MySQL to start on boot
sudo chkconfig httpd on
sudo chkconfig mysqld on


#Create Database
sudo touch commands.sql
sudo chmod 777 commands.sql
sudo cat > commands.sql << WHAM
CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'Riethuesli>12345';
drop database if exists wordpress;
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'localhost';
FLUSH PRIVILEGES;
WHAM
sudo mysql < commands.sql

# Download and extract the latest WordPress
cd /var/www/html
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xvzf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress latest.tar.gz

# Set the correct permissions
sudo chown -R apache:apache /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Create the WordPress configuration file
sudo cp wp-config-sample.php wp-config.php
sudo sed -i 's/database_name_here/wordpress/' wp-config.php
sudo sed -i 's/username_here/wordpressuser/' wp-config.php
sudo sed -i 's/password_here/Riethuesli>12345/' wp-config.php

# Restart the Apache web server
sudo service httpd restart
END

aws ec2 run-instances --image-id ami-023c11a32b0207432 --count 1 --instance-type t2.micro --key-name key_cms --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'

chmod 600 ~/.ssh/Key_cms.pem
