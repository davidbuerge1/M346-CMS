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

mkdir ~/webserver
cd ~/webserver
# erstellen der inital Datei und befüllen mit Inhalt

touch initial.txt
table_prefix='$table_prefix'

cat > initial.txt << END 
#!/bin/bash

# Update und installieren Apache web server, PHP, and MySQL
sudo yum install wget
sudo yum update -y
sudo yum install -y httpd php mysql-server php-mbstring php-dom php-mysqli

# Starten des Apache web server und MySQL
sudo service httpd start
sudo service mysqld start

# Apache web server und MySQL bei boots starten
sudo chkconfig httpd on
sudo chkconfig mysqld on

# Downlaod Wordpress
cd /var/www/html
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xvzf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress latest.tar.gz

# Berechtigungen richtig setzen
sudo chown -R apache:apache /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Wortpress Configuration file hinzufügen
sudo cp wp-config-sample.php wp-config.php
sudo sed -i 's/database_name_heredate/your_database_name/' wp-config.php
sudo sed -i 's/username_here/your_username/' wp-config.php
sudo sed -i 's/password_here/your_password/' wp-config.php

# apache neu starten
sudo service httpd restart
END 

aws ec2 run-instances --image-id ami-023c11a32b0207432 --count 1 --instance-type t2.micro --key-name key_cms --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=webserver_cms}]'
