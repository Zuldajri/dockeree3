#!/bin/bash
#
#
# Parameters
# DOCKEREE_DOWNLOAD_URL : Base location of the Docker EE packages
# UCP_PUBLIC_FQDN : UCP Public URL
# UCP_ADMIN_USERID : The UCP Admin user ID (also the ID of the Linux Administrator)
# UCP_ADMIN_PASSWORD : Password of the UCP administrator
# DTR_PUBLIC_FQDN : DTR Public URL

echo $(date) " Send-Bundle-Extra-Manager - Starting Script"

UCP_ADMIN_USERID=$1
UCP_ADMIN_PASSWORD="$2"
AZURE_CLIENT_ID=$3
AZURE_TENANT_ID=$4
AZURE_CLIENT_SECRET="$4"

# Get IP addresses
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

PRIVATE_IP_ADDRESS2=$(az vm show -d -g $RGNAME -n ucpManager2 --query "privateIps" -otsv)
PRIVATE_IP_ADDRESS3=$(az vm show -d -g $RGNAME -n ucpManager3 --query "privateIps" -otsv)

echo $PRIVATE_IP_ADDRESS2 $PRIVATE_IP_ADDRESS3

# Install sshpass
sudo apt-get install sshpass

# Send bundle.zip
sudo sshpass -p $UCP_ADMIN_PASSWORD scp /home/$UCP_ADMIN_USERID/bundle.zip $UCP_ADMIN_USERID@$PRIVATE_IP_ADDRESS2:/home/$UCP_ADMIN_USERID/bundle.zip
sudo sshpass -p $UCP_ADMIN_PASSWORD scp /home/$UCP_ADMIN_USERID/bundle.zip $UCP_ADMIN_USERID@$PRIVATE_IP_ADDRESS3:/home/$UCP_ADMIN_USERID/bundle.zip

echo $(date) " Send-Bundle-Extra-Manager - End of Script"