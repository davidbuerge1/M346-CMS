# Dokumentation M346-CMS

Dieses Repository wurde in Zusammenarbeit von Fabian Peter, Romeo Davatz und David Bürge erstellt. Diese Dokumentation beschreibt das gesamte Prokjekt von der Planung bis zum fertigen Script. Ebenfalls folgt eine Anleitung, wie das CMS anhand unseres Scriptes zu installieren ist.

[**1. Projektinformationen**](#anker)  
[**1.1 CMS**](#anker1)  
[**1.2 Aufgaben und Zuständigkeit**](#anker2)  
[**2. Installation und Konfiguration**](#anker3)  
[**3. Anleitung**](#anker4)  
[**4. Testfälle**](#anker5)  
[**5. Reflexion**](#anker6)
<a name="anker"></a>
## 1. Projektinformationen
In diesem Abschnitt werden grundlegende Informationen zum Projekt wie die gegebene Aufgabe, Wahl des CMS und die Aufgabenverteilung in der Gruppe aufgezählt.

<a name="anker1"></a>
### 1.1 Aufgabenstellung
Für das Prokjekt, musste ein CMS auf einer AWS instanz erstellt werden. Der installation der Instanzen und dem CMS sollte schlussendlich Automatisiert werden.. 

<a name="anker2"></a>
### 1.1 Wahl CMS  
Ein Content-Management-System (CMS) ist eine Softwareanwendung, die es Benutzern ermöglicht, Inhalte auf Websites zu erstellen, zu bearbeiten und zu verwalten, ohne umfangreiche Programmierkenntnisse zu benötigen. Es ist eine effektive Lösung für die Verwaltung von digitalen Inhalten, sei es Texte, Bilder, Videos oder andere Medien.

Das CMS bietet eine benutzerfreundliche Oberfläche, die es Benutzern ermöglicht, Inhalte direkt im Webbrowser zu erstellen und zu bearbeiten. Es ermöglicht die Organisation von Inhalten in einer hierarchischen Struktur, um eine einfache Navigation zu gewährleisten. Ein CMS erleichtert auch die Zusammenarbeit verschiedener Benutzer, indem es die Berechtigungen und Zugriffslevel verwaltet.

Als CMS haben wir uns für WordPress entschieden, da uns dies bereits bekannt war. Ausserdem ist es eines der bekanntesten CMS, daher findet man man ausreichent Informationen und Dokumentationen im Internet, was uns die Arbeit erleichtern konnte.

<a name="anker3"></a>
### 1.2 Aufgaben und Zuständigkeit
Für das Prokelt musste das CMS umgesetzt werden, sowie eine ausführliche Dokumentation gestaltet werden. Grundsätzlich war jeder in der gruppe bei allem beteiligt. Trotzdem konzentirerten sich  Fabian und David eher auf die Installation des CMS, wobei sich Romeo ausführlicher mit der Dokumentation befasste. 

<a name="anker4"></a>
## 2. Installation und Konfiguration
  Für die Umsetzung haben wir 3 verschiedene FIles verwendet. Das [setup-wordpress-aws.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/setup-wordpress-aws.sh) diente dabei als die "grundlegende" Datei, inder die Sicherheitsgruppen, Rules sowie die Schlüsselpaare definiert wurden. Das [DB-server-setup.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/server-setup/DB-server-setup.sh), wurde dabei als Konfigurationsdatei für die Datenbank verwendet. Das [CMS-server-setup.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/server-setup/CMS-server-setup.sh) wurde als Konfigurationsdatei für die Instanz verwendet, aufder das CMS läuft. Zum Code finden Sie weitere Informationen unter [Code erklärt](#anker8).

  Am Anfang waren wir uns unschlüssig, wie wir das Projekt umsetzen könnten. Nach reichlichem informieren, haben wir uns dazu entschieden Docker zu verwenden, da es sehr Effizient ist und auch in Professionellen Umgebungen öfters verwendet wird. Ausserdem haben wir zwei verschiedene EC2 Instanzen verwendet, wobei die Instanz der Datenbank durch eine Sicherheitsgruppe geschützt ist so, dass nicht aus dem Internet direkt darauf zugegriffen werden kann. Die CMS Instanz, kommuniziert über die Interne IP-Adresse mit der Datenbank.

  

<a name="anker8"></a>
### Erklärung des Codes
## [setup-wordpress-aws.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/setup-wordpress-aws.sh)

Hier wird ein zufälliges Passwort generiert, welches von den Instanzen übernommen wird, um die Sicherheit zu steigern.
```
password=$(openssl rand -base64 36 | tr -dc 'a-zA-Z0-9' | head -c 54)
```
Dieser Code erstellt das Init-file für die Datenbank. Dabei werden die benötigten Packages installiert sowie befehle aufgeschrieben, die später auf der Instanz ausgeführt werden sollen. Beispielsweise das ausühren des Datenbank Setups. Ausserdem wird die Setupdatei der Datenbank direkt aus unserem Repository heruntergeladen und mithilfe des zuvor erstellten Passworts ausgeführt.
```
cat <<END > init.yaml
#cloud-config
package_update: true
packages:
  - curl
  - mariadb-server
  - git
runcmd:
  - git clone "https://github.com/davidbuerge1/M346-CMS.git" setup
  - cd setup/server-setup
  - chmod +x DB-server-setup.sh
  - sudo bash DB-server-setup.sh $password
END
```
Hier wird ein Keypair für den Zugriff auf die Instanz erstellt.
```
aws ec2 create-key-pair --key-name WordPress-AWS-Key --key-type rsa --query 'KeyMaterial' --output text > ./WordPress-AWS-Key.pem
```
Mit diesem Code werden die beiden Sicherheitsgruppen erstellt. Eine für die Interne Kommunikation zwischen den Instanzen und die andere für die Kommunikation mit externen Netzwerken.
```
aws ec2 create-security-group --group-name WordPress-net-Intern --description "Internes-Netzwerk-fuer-WordPressDB"
aws ec2 create-security-group --group-name WordPress-net-Extern --description "Externes-Netzwerk-fuer-WordPressCMS"
```
Hier wird die Instance der Datenbank gestartet.
```
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name WordPress-AWS-Key --security-groups WordPress-net-Intern --iam-instance-profile Name=LabInstanceProfile --user-data file://init.yaml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WordPressDB}]'
```
Mit folgendem Code wird die Interne sowie die Externe IP-Adresse des DB-Servers ermittelt, um später die Kommunikation zu gewährleisten.
```
WPDBInstanceId=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text --filters "Name=tag:Name,Values=WordPressDB")
WPDBPrivateIpAddressip=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --filters "Name=tag:Name,Values=WordPressDB")
```
Hier wird die Id der Security-group ausgelesen, um später Regeln den entsprechenden Regeln den Gruppen zuzuweisen.
```
SecurityGroupId=$(aws ec2 describe-security-groups --group-names 'WordPress-net-Extern' --query 'SecurityGroups[0].GroupId' --output text)
```
Hier werden die Regeln für die Security-Groups definiert.
```
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Intern --protocol tcp --port 3306 --source-group $SecurityGroupId
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Intern --protocol tcp --port 22 --source-group $SecurityGroupId
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name WordPress-net-Extern --protocol tcp --port 22 --cidr 0.0.0.0/0
```
Mithilfe dieses Codes wird das Init-file für die CMS-instanz erstellt. Wie auch bei der Datenbank, wird die Setupdatei direkt aus dem Repository heruntergeladen und ausgeführt
```
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
  - git clone "https://github.com/davidbuerge1/M346-CMS.git" WordPressCMS
  - cd WordPressCMS/server-setup
  - chmod +x CMS-server-setup.sh
  - sudo bash CMS-server-setup.sh $WPDBPrivateIpAddressip $password WordPressDB
END
```
Hier wird die zweite Instanz  mithilfe des Init-files erstellt.
``` 
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name WordPress-AWS-Key --security-groups WordPress-net-Extern --iam-instance-profile Name=LabInstanceProfile --user-data file://init.yaml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WordPressCMS}]'
```

## [CMS-server-setup.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/server-setup/CMS-server-setup.sh)
Dieser Befehl führt eine Änderung in der Datei "50-server.cnf" durch, die sich im Verzeichnis "/etc/mysql/mariadb.conf.d/" befindet. Dabei wird die Option "bind-address" so modifiziert, dass sie auf "127.0.0.1" festgelegt wird.
```
sudo sed -i 's/bind-address\s*=.*/bind-address = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf
```
Der erste Befehl weist dem Benutzer 'root' alle Privilegien für alle Datenbanken zu, ermöglicht den Zugriff von jedem beliebigen Host aus und setzt das Passwort, das als Parameter '$1' übergeben wird. Der zweite Befehl aktualisiert die Berechtigungen, um die Änderungen wirksam zu machen. Der dritte Befehl erstellt eine neue Datenbank mit dem Namen "WordPressDB" unter Verwendung des angegebenen Benutzernamen und Passworts. Die Befehle werden alle mit Root-Berechtigungen ausgeführt, die durch sudo verliehen werden, und erfordern eine Passwortabfrage, um sich als Benutzer 'root' anzumelden.
```
echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;" | sudo mysql -u root -p"$1"
echo "FLUSH PRIVILEGES;" | sudo mysql -u root -p"$1"
echo "create database WordPressDB;" | sudo mysql -u root -p"$1"
```
Mithilfe dieses Codes werden die beiden Ports freigegeben, um die Kommunikation zu ermöglichen.
```
ufw allow 3306
ufw allow 22
```
Anpassung der Mariadb conf
```
sed -i '/^bind-address/ s/^/#/' /etc/mysql/mariadb.conf.d/50-server.cnf
```

## [CMS-server-setup.sh](https://github.com/davidbuerge1/M346-CMS/blob/main/server-setup/CMS-server-setup.sh)
Installation von Docker
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt update -y
apt-get install docker-ce docker-ce-cli containerd.io -y
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```
Anpassung der des docker-compose.yml
```
cd /WordPressCMS/server-setup/docker
sed -i "s/<DB-Host>/$1/g" docker-compose.yml
sed -i "s/<DB-User>/root/g" docker-compose.yml
sed -i "s/<DB-Password>/$2/g" docker-compose.yml
sed -i "s/<DB-Name>/$3/g" docker-compose.yml
```
    

<a name="anker5"></a>
## 3. Anleitung  
### 1. Schritt 
Hier sind die Voraussetungen, bevor die Instanzen installiert werden können.
 
- [X] Vollständige Konfiguration vom AWS Client auf einer Ubuntu-maschine.
- [x] Es darf kein Key mit dem Namen 
  
### 2. Schritt
  
  
### 3. Schritt  

### 4. Schritt  

  
### 5. Anpassungen bei Neustart eines Servers  

  
### 6. Löschen aller Ressourcen  

<a name="anker6"></a>
## 4. Testfälle  
**Testfall 1** 
   
  
**Testfall 2**  

<a name="anker7"></a>
## 5. Reflexion  
**David Bürge**  


**Fabian Peter**


**Romeo Davatz**
