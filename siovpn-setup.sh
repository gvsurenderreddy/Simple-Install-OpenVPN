#!/bin/bash

## This script is developed by Kevin Allioli
## Script Name: siovpn-setup.sh Version 1.1
## Website: http://www.it4it.fr
## Thank you for your interest in Simple install OpenVPN

reset
echo "#####################################";
echo "#       Simple Install OpenVPN      #";
echo "#          By Kevin Allioli         #";
echo "#         http://www.it4it.fr       #";
echo "#####################################";
echo "";
echo "What is the distribution used ?";
echo "";
echo "1) For distribution based on Debian (Debian, Ubuntu...";
echo "2) For distribution based on RHEL (CentOS, Fedora...";
read answer
if [ $answer = "1" ] || [ $answer = "DEBIAN" ]
then
cd /tmp 
wget https://raw.githubusercontent.com/kallioli/Simple-Install-OpenVPN/master/siovpn-debian.sh
chmod +x siovpn-debian.sh
./siovpn-debian.sh
else
cd /tmp
wget https://raw.githubusercontent.com/kallioli/Simple-Install-OpenVPN/master/siovpn-centos.sh
chmod +x siovpn-centos.sh
./siovpn-centos.sh
fi
rm *.sh
exit 0
