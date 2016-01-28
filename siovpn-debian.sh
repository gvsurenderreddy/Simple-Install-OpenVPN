#!/bin/bash

# This script is developed by Kevin Allioli
# Script Name: setup-debian.sh Version 1.1
# Website: http://www.it4it.fr
# Thank you for your interest in Simple install OpenVPN

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "The script must be run as root" 1>&2
  exit 1
fi

## Install prerequisite
apt-get update
apt-get install aptitude -y

APT_GET="aptitude install"
PACKAGE_LIST="openvpn zip easy-rsa perl"

## Package Installation and configuration
$APT_GET $PACKAGE_LIST -y
mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
chown -R $USER /etc/openvpn/easy-rsa/

## Set Variable for CA
read -p "Insert the Country Key(Example : FR): " key_country 
read -p "Insert the Province Key (Example : IDF): " key_province
read -p "Insert the City Key (Example : Paris): " key_city
read -p "Insert the Organisation Key (Example : IT4IT): " key_org
read -p "Insert the Email Key (Example : contact@it4it.fr): " key_email

sed -i -e "s/^export KEY_COUNTRY=/export KEY_COUNTRY=\"$key_country\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_PROVINCE=/export KEY_PROVINCE=\"$key_province\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_CITY=/export KEY_CITY=\"$key_city\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_ORG=/export KEY_ORG=\"$key_org\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_EMAIL=/export KEY_EMAIL=\"$key_email\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_CN=/export KEY_CN=\"$(hostname --fqdn)\"/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_NAME=/export KEY_NAME=changeme/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export KEY_OU=/export KEY_OU=changeme/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export PKCS11_MODULE_PATH=/export PKCS11_MODULE_PATH=changeme/g" /etc/openvpn/easy-rsa/vars
sed -i -e "s/^export PKCS11_PIN=/export PKCS11_PIN=1234/g" /etc/openvpn/easy-rsa/vars


## Key generation and export
ln -s /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
perl -p -i -e 's|^(subjectAltName=)|#$1|;' /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
cd /etc/openvpn/easy-rsa/
source vars
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
openvpn --genkey --secret keys/ta.key    
cp keys/ca.crt keys/ta.key keys/server.crt keys/server.key keys/dh2048.pem /etc/openvpn/

## Administrative folder creation
mkdir -p /etc/openvpn/jail/tmp
mkdir /etc/openvpn/clientconf
mkdir /etc/openvpn/script

## Create the server.conf file
read -p "Insert the protocol which use by the server (Example : tcp or udp): " protocol
read -p "Insert the port which use by the server (Example : 443): " server_port
read -p "Insert the VPN network IP (Example : 10.8.0.0): " network_ip
read -p "Insert the VPN network Netmask (Example : 255.255.255.0): " network_mask
read -p "Insert IP of the first DNS Server (Example : 8.8.8.8): " network_dns1
read -p "Insert IP of the second DNS Server (Example : 8.8.4.4): " network_dns2

cat <<EOF>/etc/openvpn/server.conf
# Server $protocol/$server_port
mode server
proto $protocol
port $server_port
dev tun
# Keys et certificates
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0
cipher AES-256-CBC
# Network
server $network_ip $network_mask
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS $network_dns1"
push "dhcp-option DNS $network_dns2"
keepalive 10 120
# Securite
user nobody
group nogroup
chroot /etc/openvpn/jail
persist-key
persist-tun
comp-lzo
# Log
verb 3
mute 20
status openvpn-status.log
log-append /var/log/openvpn.log
EOF

service openvpn start

## Post Install Setting

echo "net.ipv4.ip_forward=1">>/etc/sysctl.d/10-ip_forward.conf
sysctl -p /etc/sysctl.d/10-ip_forward.conf

## Add scripts for user management

cd /etc/openvpn/script
if [ ! -f /usr/bin/adduserovpn ]
then
        wget https://raw.githubusercontent.com/kallioli/Simple-Install-OpenVPN/master/adduserovpn.sh
fi
 
chmod +x /etc/openvpn/script/adduserovpn.sh
ln -s /etc/openvpn/script/adduserovpn.sh /usr/bin/adduserovpn

if [ ! -f /usr/bin/deluserovpn ]
then
        wget https://raw.githubusercontent.com/kallioli/Simple-Install-OpenVPN/master/deluserovpn.sh
fi

chmod +x /etc/openvpn/script/deluserovpn.sh
ln -s /etc/openvpn/script/deluserovpn.sh /usr/bin/deluserovpn

clear
echo "To finish the installation please add this firewall rule:"
echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE"
exit 0