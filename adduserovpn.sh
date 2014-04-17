#!/bin/bash

## This script is developed by Kevin Allioli
## Script Name: adduserovpn.sh Version 1.0
## Website: http://www.openology.net
## Thank you for your interest in Simple install OpenVPN

## Verify the script must be run as root
if [ $EUID -ne 0 ]; then
  echo "The script must be run as root" 1>&2
  exit 1
fi

## Parameters test
if [ $# -ne 1 ]; then
echo "You must be enter the username in parameters: # sudo $0 <username>" 1>&2
  exit 1
fi

SU="sudo"

## Choice menu
cd /etc/openvpn/easy-rsa
echo "Creation of OpenVPN client: $1"
echo "Please choose the type of certificate:"
echo "1) Certificate WITHOUT password"
echo "2) Certificate WITH password"
read key
case $key in
1)
		echo "Creation of the certificate WITHOUT password for the client $1"
		source vars
		./build-key $1
		;;
2)
		echo "Creation of the certificate WITH password for the client $1"
		source vars
		./build-key-pass $1
		;;
*)
		echo "Wrong choice!"
		echo "Stop script"
		exit 0
;;
esac

## User creation
$SU mkdir /etc/openvpn/clientconf/$1
$SU cp /etc/openvpn/ca.crt /etc/openvpn/ta.key keys/$1.crt keys/$1.key /etc/openvpn/clientconf/$1/
$SU chmod -R 777 /etc/openvpn/clientconf/$1
cd /etc/openvpn/clientconf/$1

## Generate user configuration file

$SU cat <<EOF >$1.conf
## Client
client
dev tun
proto $protocol-client
remote `wget -qO- api.openology.net/ip` $server_port
resolv-retry infinite
cipher AES-256-CBC

## Cles
ca ca.crt
cert $1.crt
key $1.key
tls-auth ta.key 1

## Securite
nobind
persist-key
persist-tun
comp-lzo
verb 3
EOF

$SU cp /etc/openvpn/clienconf/$1/$1.conf /etc/openvpn/clientconf/$1.ovpn
$SU zip $1.zip *.*
echo "Creation du client OpenVPN $1 termine"
echo "/etc/openvpn/clientconf/$1/$1.zip"
echo "---"
