#!/bin/bash

echo "Willkommen beim Setup für Wordpress auf AWS!"

password=$(openssl rand -base64 36 | tr -dc 'a-zA-Z0-9' | head -c 54)

cat <<END > init.yaml
#cloud-config
package_update: true
packages:
  - curl
  - mariadb-server
  - git
runcmd:
  - git clone "https://github.com/davidbuerge1/Wordpress-AWS.git" setup
  - cd setup/server-setup
  - chmod +x setup-wordpress-aws.sh
  - bash DB-server-setup.sh $password
END

aws ec2 create-key-pair --key-name WordPress-AWS-Key --key-type rsa --query 'KeyMaterial' --output text > ./WordPress-AWS-Key.pem
aws ec2 create-security-group --group-name WordPress-net-Intern --description "Internes-Netzwerk-fuer-WordPressDB"
aws ec2 create-security-group --group-name WordPress-net-Extern --description "Externes-Netzwerk-fuer-WordPressCMS"
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name WordPress-AWS-Key --security-groups WordPress-net-Intern --iam-instance-profile Name=LabInstanceProfile --user-data file://init.yaml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WordPressDB}]'

WPDBInstanceId=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text --filters "Name=tag:Name,Values=WordPressDB")
WPDBPrivateIpAddress-ip=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --filters "Name=tag:Name,Values=WordPressDB")

SecurityGroupId=$(aws ec2 describe-security-groups --group-names 'WordPress-net-Extern' --query 'SecurityGroups[0].GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-name WordPress-net-Intern --protocol tcp --port 3306 --source-group $SecurityGroupId
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Intern --protocol tcp --port 22 --source-group $SecurityGroupId
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 22 --cidr 0.0.0.0/0

cat <<END > init.yaml
#cloud-config
package_update: true
packages:
  - git
  - ca-certificates
  - curl
  - gnupg
  - software-properties-common
  - apt-transport-https
  - cron
  - snapd
runcmd:
  - git clone "https://github.com/davidbuerge1/Wordpress-AWS.git" WordPressCMS
  - cd WordPressCMS/server-setup 
  - chmod +x setup-wordpress-aws.sh
  - bash CMS-server-setup.sh $WPDBPrivateIpAddress-ip $password WordPressDB
END

aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name WordPress-AWS-Key --security-groups WordPress-net-Extern --iam-instance-profile Name=LabInstanceProfile --user-data file://init.yaml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WordPressCMS}]'

