#!/bin/bash

## This script is developed by Kevin Allioli
## Script Name: deluserovpn.sh Version 1.0
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

## Validation menu
cd /etc/openvpn/easy-rsa
echo "Revoke OpenVPN client: $1"
echo "Are you sure to revoke $1"
echo "1) Yes I'm sure"
echo "2) No I wan't stop"
read key
case $key in
1)
		echo "Revoking $1 from OpenVPN Server"
		source vars
		./revoke-full $1
		rm -R /etc/openvpn/clientconf/$1
		;;

2)		echo "OK $1 is alway an OpenVPN user"
		exit 0
		;;

*)		echo "Wrong choice"
		echo "Return to system"
		exit 0
;;
esac
exit 0
