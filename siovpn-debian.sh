#!/bin/bash
#
# Installation automatique d'OpenVPN sous Ubuntu/Debian
#
# Kevin Allioli
# Script libre: GPLv2
#
# Syntaxe: root> ./siovpn-debian.sh
#

script_version="1.1"

# Globals variables
#-----------------------------------------------------------------------------

DATE=`date +"%Y%m%d%H%M%S"`
CMD_APT="/usr/bin/aptitude install -y"
PACKAGES_LIST="openvpn zip easy-rsa perl"

TEMP_FOLDER="/tmp/siovpn-debian.$DATE"
BACKUP_FILE="/tmp/siovpn-debian-$DATE.tgz"
LOG_FILE="/tmp/siovpn-debian-$DATE.log"

# Functions
#-----------------------------------------------------------------------------

displaymessage() {
  echo "$*"
}

displaytitle() {
  displaymessage "------------------------------------------------------------------------------"
  displaymessage "$*"  
  displaymessage "------------------------------------------------------------------------------"
}

displayerror() {
  displaymessage "$*" >&2
}

# First parameter: ERROR CODE
# Second parameter: MESSAGE
displayerrorandexit() {
  local exitcode=$1
  shift
  displayerror "$*"
  exit $exitcode
}

# First parameter: MESSAGE
# Others parameters: COMMAND (! not |)
displayandexec() {
  local message=$1
  echo -n "[En cours] $message"
  shift
  $* >> $LOG_FILE 2>&1 
  local ret=$?
  if [ $ret -ne 0 ]; then
    echo -e "\r\e[0;31m   [ERROR]\e[0m $message"
    # echo -e "\r   [ERROR] $message"
  else
    echo -e "\r\e[0;32m      [OK]\e[0m $message"
    # echo -e "\r      [OK] $message"
  fi 
  return $ret
}

# Function: backup
backup() {
  displayandexec "Archive current configuration" tar zcvf $BACKUP_FILE /etc/openvpn
}

# Function: Start OpenVPN
start() {
  sleep 2
  displayandexec "Start OpenVPN" service openvpn start
}

# Function: Stop OpenVPN
stop() {
  sleep 2
  displayandexec "Stop OpenVPN" service openvpn stop
}

# Function: Affiche le résumé de l'installation
end() {
  echo ""
  echo "=============================================================================="
  echo "Installation is finished"
  echo "=============================================================================="
  if [ -f $BACKUP_FILE ]; then
    echo "Backup configuration file         : $BACKUP_FILE"
  fi
  echo "Configuration file folder         : /etc/openvpn"
  echo "OpenVPN startup script            : /etc/init.d/openvpn"
  echo "Log for the installation script   : $LOG_FILE"
  echo "=============================================================================="
  echo ""
}

# Main program
#-----------------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
	echo "This script should be run as root."
	echo "Syntaxe: sudo $0"
	exit 1
fi
if [ -d /etc/openvpn ]; then
 displaytitle "-- Stop current OpenVPN process"
 stop
 displaytitle "-- Backup the current configuration in $BACKUP_FILE"
 backup
fi

# Set variables
#-----------------------------------------------------------------------------
displaytitle "-- Set value for CA"
read -p "Insert the Country Key(Example : FR): " key_country
read -p "Insert the Province Key (Example : IDF): " key_province
read -p "Insert the City Key (Example : Paris): " key_city
read -p "Insert the Organisation Key (Example : IT4IT): " key_org
read -p "Insert the Email Key (Example : contact@it4it.fr): " key_email

displaytitle "-- Set value for the server configuration"
read -p "Insert the protocol which use by the server (Example : tcp or udp): " protocol
read -p "Insert the port which use by the server (Example : 443): " server_port
read -p "Insert the VPN network IP (Example : 10.8.0.0): " network_ip
read -p "Insert the VPN network Netmask (Example : 255.255.255.0): " network_mask
read -p "Insert IP of the first DNS Server (Example : 8.8.8.8)" network_dns1
read -p "Insert IP of the second DNS Server (Example : 8.8.4.4)" network_dns2

# OpenVPN Installation
#-----------------------------------------------------------------------------
displaytitle "-- OpenVPN Installation"
displayandexec "Repository update" aptitude update
displayandexec "Install prerequisite" $CMD_APT $PACKAGES_LIST
displayandexec "CA Initialisation" mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
rm /etc/openvpn/easy-rsa/vars
displayandexec "Generate vars file" cat <<EOF>/etc/openvpn/easy-rsa/vars
export OPENSSL="openssl"
export PKCS11TOOL="pkcs11-tool"
export GREP="grep"
export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`
export KEY_DIR="$EASY_RSA/keys"
echo NOTE: If you run ./clean-all, I will be doing a rm -rf on $KEY_DIR
export PKCS11_MODULE_PATH=changeme
export PKCS11_PIN=1234
export KEY_SIZE=2048
export CA_EXPIRE=3650
export KEY_EXPIRE=3650
export KEY_COUNTRY="$key_country"
export KEY_PROVINCE="$key_province"
export KEY_CITY="$key_city"
export KEY_ORG="$key_org"
export KEY_EMAIL="key_email"
export KEY_OU="MyOrganizationalUnit"
export KEY_NAME="EasyRSA"
export KEY_CN="$(hostname --fqdn)"
EOF
chown -R $USER /etc/openvpn/easy-rsa/

#displayandexec "Modifying country  value" sed -i -e "s/^export KEY_COUNTRY=/export KEY_COUNTRY=\"$key_country\"/g" /etc/openvpn/easy-rsa/vars
#displayandexec "Modifying province value" sed -i -e "s/^export KEY_PROVINCE=/export KEY_PROVINCE=\"$key_province\"/g" /etc/openvpn/easy-rsa/vars
#displayandexec "Modifying city value" sed -i -e "s/^export KEY_CITY=/export KEY_CITY=\"$key_city\"/g" /etc/openvpn/easy-rsa/vars
#displayandexec "Modifying organisation value" sed -i -e "s/^export KEY_ORG=/export KEY_ORG=\"$key_org\"/g" /etc/openvpn/easy-rsa/vars
#displayandexec "Modifying e-mail value" sed -i -e "s/^export KEY_EMAIL=/export KEY_EMAIL=\"$key_email\"/g" /etc/openvpn/easy-rsa/vars
#displayandexec "Modifying common name value" sed -i -e "s/^export KEY_CN=/export KEY_CN=\"$(hostname --fqdn)\"/g" /etc/openvpn/easy-rsa/vars
#sed -i -e "s/^export KEY_NAME=/export KEY_NAME=changeme/g" /etc/openvpn/easy-rsa/vars
#sed -i -e "s/^export KEY_OU=/export KEY_OU=changeme/g" /etc/openvpn/easy-rsa/vars
#sed -i -e "s/^export PKCS11_MODULE_PATH=/export PKCS11_MODULE_PATH=changeme/g" /etc/openvpn/easy-rsa/vars
#sed -i -e "s/^export PKCS11_PIN=/export PKCS11_PIN=1234/g" /etc/openvpn/easy-rsa/vars

displaytitle "-- Key generation and export"
ln -s /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
perl -p -i -e 's|^(subjectAltName=)|#$1|;' /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
cd /etc/openvpn/easy-rsa/
displayandexec "Loading CA environnement" source vars
displayandexec "Purge CA" ./clean-all
displayandexec "Build Diffie-Hellman Key" ./build-dh
displayandexec "Initializing CA"./pkitool --initca
displayandexec "Generate server certificate"./pkitool --server server
displayandexec "Generate server exchange private key" openvpn --genkey --secret keys/ta.key    
displayandexec "Import server certificates in OpenVPN folder" cp keys/ca.crt keys/ta.key keys/server.crt keys/server.key keys/dh2048.pem /etc/openvpn/

displaytitle "-- Create OpenVPN folders"
displayandexec "Create jail folder" mkdir -p /etc/openvpn/jail/tmp
displayandexec "Create client configuration folder" mkdir /etc/openvpn/clientconf
displayandexec "Create script folder" mkdir /etc/openvpn/script

displaytitle "-- Server configuration file creation"
displayandexec "Generate server.conf" cat <<EOF>/etc/openvpn/server.conf
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

start

## Post Install Setting

displayandexec "" echo "net.ipv4.ip_forward=1">>/etc/sysctl.d/10-ip_forward.conf
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
