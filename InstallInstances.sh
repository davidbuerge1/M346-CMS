#!bin\bash

# erstellen der Keypairs
aws ec2 create-key-pair --key-name aws-cli-key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/aws-cli-key.pem

# erstellen der Sequirty Group
aws ec2 create-security-group --group-name sec-group --description "Webserver-EC2" > /dev/null

# Secuirty Group autorisieren
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol tcp --port 3306 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name sec-group --protocol icmp --port -1 --cidr 0.0.0.0/0 
