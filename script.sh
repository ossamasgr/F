#!/bin/sh -e

sleep 15

# Install NSS Certificate
if ! [ -f "NssCertificate.zip" ]; then
    echo "The file NssCertificate.zip was not found."
    echo "Put this script in the same path where NssCertificate.zip is."
    echo "And run it again."
    exit 1
fi

echo "Installing Certificate"
sudo nss install-cert NssCertificate.zip

# NSS Service Interface and Default Gateway IP Configuration
# Parameters passed by user input via ARM Template
echo "Set IP Service Interface IP Address and Default Gateway"
smnet_dev=${SMNET_IPMASK}
smnet_dflt_gw=${SMNET_GW}
sudo nss configure --cliinput ${SMNET_IPMASK},${SMNET_GW}

echo "Successfully Applied Changes"

# Configure NSS Settings
NEW_NAME_SERVER_IPS=()
NEW_NS="n"
echo "Do you wish to add a new nameserver? <n:no y:yes> , press enter for [n]"
read RESP
until [ -z "$RESP" ] || [ "$RESP"  != "y" ]; do
    echo "Enter the nameserver IP address:"
    read NEW_NAME_SERVER_IP
    until ! [ -z "$NEW_NAME_SERVER_IP" ] && [[ $NEW_NAME_SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
        echo "Please enter a valid nameserver IP address:"
        read NEW_NAME_SERVER_IP
    done
    NEW_NAME_SERVER_IPS+=("$NEW_NAME_SERVER_IP")
    echo "Do you wish to add a new nameserver? <n:no y:yes> , press enter for [n]"
    read RESP
done

# NSS Server Interface IP Configuration
echo "Enter service interface IP address with netmask. (ex. 192.168.100.130/25): "
read SMNET_IPMASK

# NSS Default Gateway Configuration
SMNET_GW=$(netstat -r | grep default | awk '{print $2}')
#echo "Enter service interface default gateway IP address, press enter for [${SMNET_GW}]: "
read DEFAULT_GW_ENTERED
if ! [ -z "${DEFAULT_GW_ENTERED}" ]; then
    SMNET_GW=${DEFAULT_GW_ENTERED}
fi
SERVERS=$(sudo nss dump-config | grep "nameserver:"|  tr  "nameserver:" " " | tr [:space:] " ")
IFS=', ' read -r -a EXISTING_NAME_SERVERS <<< "$SERVERS"
# -----
SKIP_SERVERS=""
for server in "${EXISTING_NAME_SERVERS[@]}"
do
    SKIP_SERVERS+="\n"
done
NEW_SERVERS_COMMAND=""
for new_server in "${NEW_NAME_SERVER_IPS[@]}"
do
    NEW_SERVERS_COMMAND+="y\n${new_server}\n"
done
printf "${SKIP_SERVERS}${NEW_SERVERS_COMMAND}\n${SMNET_IPMASK}\n${SMNET_GW}\n\n" | sudo nss configure

# Download NSS Binaries
sudo nss update-now
echo "Connecting to server..."
echo "Downloading latest version" # Wait until system echo back the next message
echo "Installing build /sc/smcdsc/nss_upgrade.sh" # Wait until system echo back the next message
echo "Finished installation!"

 #Check NSS Version
sudo nss checkversion

# Enable the NSS to start automatically
sudo nss enable-autostart
echo "Auto-start of NSS enabled "

# Start NSS Service
sudo nss start
echo "NSS service running."

# Dump all Important Configuration
sudo netstat -r > nss_dump_config.log
sudo nss dump-config > nss_dump_config.log
sudo nss checkversion >> nss_dump_config.log
sudo nss troubleshoot netstat|grep tcp >> nss_dump_config.log
sudo nss test-firewall >> nss_dump_config.log
sudo nss troubleshoot netstat >> nss_dump_config.log
/sc/bin/smmgr -ys smnet=ifconfig >> nss_dump_config.log
# cat /sc/conf/sc.conf | egrep "smnet_dev|smnet_dflt_gw" >> nss_dump_config.log
# smnet_dev=/dev/tap0:172.31.17.111/20
# smnet_dflt_gw=172.31.16.1

"
exit 0
