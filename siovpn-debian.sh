#!/bin/bash

# This script is developed by Kevin Allioli
# Script Name: setup-debian.sh Version 1.0
# Website: http://www.openology.net
# Thank you for your interest in Simple install OpenVPN

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "The script must be run as root" 1>&2
  exit 1
fi

## Install prerequisite
apt-get update
apt-get install aptitude sudo -y

SU="sudo"
APT_GET="aptitude install"
PACKAGE_LIST="openvpn zip"

## Full System Update
$SU aptitude upgrade -y

## Package Installation and configuration
$SU $APT_GET $PACKAGE_LIST -y
$SU mkdir /etc/openvpn/easy-rsa/
$SU cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/* /etc/openvpn/easy-rsa/
$SU chown -R $USER /etc/openvpn/easy-rsa/

## Set Variable for CA
echo "Insert the Country Key(Example : FR)"
read key_country
echo "Insert the Province Key (Example : IDF)"
read key_province
echo "Insert the City Key (Example : Paris)"
read key_city
echo "Insert the Organisation Key (Example : Openology)"
read key_org
echo "Insert the Email Key (Example : contact@openology.net)"
read key_email

$SU sed -i '/export KEY_COUNTRY=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_PROVINCE=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_CITY=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_ORG=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_EMAIL=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_CN=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_NAME=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export KEY_OU=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export PKCS11_MODULE_PATH=/d' /etc/openvpn/easy-rsa/vars
$SU sed -i '/export PKCS11_PIN=/d' /etc/openvpn/easy-rsa/vars

$SU echo "export KEY_COUNTRY=\"$key_country\"">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_PROVINCE=\"$key_province\"">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_CITY=\"$key_city\"">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_ORG=\"$key_org\"">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_EMAIL=\"$key_email\"">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_EMAIL=mail@host.domain">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_CN=changeme">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_NAME=changeme">>/etc/openvpn/easy-rsa/vars
$SU echo "export KEY_OU=changeme">>/etc/openvpn/easy-rsa/vars
$SU echo "export PKCS11_MODULE_PATH=changeme">>/etc/openvpn/easy-rsa/vars
$SU echo "export PKCS11_PIN=1234">>/etc/openvpn/easy-rsa/vars


## Key generation and export
$SU ln -s /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
cd /etc/openvpn/easy-rsa/
source vars
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
$SU openvpn --genkey --secret keys/ta.key    
$SU cp keys/ca.crt keys/ta.key keys/server.crt keys/server.key keys/dh1024.pem /etc/openvpn/

## Administrative folder creation
$SU mkdir /etc/openvpn/jail
$SU mkdir /etc/openvpn/clientconf
$SU mkdir /etc/openvpn/script

## Create the server.conf file
echo "Insert the protocol which use by the server (Example : tcp or udp)"
read protocol
echo "Insert the port which use by the server (Example : 443)"
read server_port
echo "Insert the VPN network IP (Example : 10.8.0.0)"
read network_ip
echo "Insert the VPN network Netmask (Example : 255.255.255.0)"
read network_mask
echo "Insert IP of the first DNS Server (Example : 8.8.8.8)"
read network_dns1
echo "Insert IP of the second DNS Server (Example : 8.8.4.4)"
read network_dns2

$SU cat <<EOF>/etc/openvpn/server.conf
# Server $protocol/$server_port
mode server
proto $protocol
port $server_port
dev tun

# Keys et certificates
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
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

$SU /etc/init.d/openvpn start

## Post Install Setting

$SU sed -i '/#net.ipv4.ip_forward=1/d' /etc/sysctl.conf
$SU echo "net.ipv4.ip_foward=1">>/etc/sysctl.conf
$SU sysctl -p

## Add scripts for user management

cd /etc/openvpn/script
if [ ! -f /usr/bin/adduserovpn ]
then
        wget http://download.openology.net/project/siovpn/adduserovpn.sh
fi
 
chmod +x /etc/openvpn/script/adduserovpn.sh
ln -s /etc/openvpn/script/adduserovpn.sh /usr/bin/adduserovpn

if [ ! -f /usr/bin/deluserovpn ]
then
        wget http://download.openology.net/project/siovpn/deluserovpn.sh
fi

chmod +x /etc/openvpn/script/deluserovpn.sh
ln -s /etc/openvpn/script/deluserovpn.sh /usr/bin/deluserovpn

clear
echo "To finish the installation please add this firewall rule:"
echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE"
exit 0
