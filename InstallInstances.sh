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

aws ec2 run-instances --image-id ami-023c11a32b0207432 --count 1 --instance-type t2.micro --key-name key_cms --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=webserver_cms}]'
