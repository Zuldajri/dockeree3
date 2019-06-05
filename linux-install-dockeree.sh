#!/bin/bash
#
#
# Parameters
# DOCKEREE_DOWNLOAD_URL : Base location of the Docker EE packages
# UCP_PUBLIC_FQDN : UCP Public URL
# UCP_ADMIN_USERID : The UCP Admin user ID (also the ID of the Linux Administrator)
# UCP_ADMIN_PASSWORD : Password of the UCP administrator
# DTR_PUBLIC_FQDN : DTR Public URL

echo $(date) " linux-install-dockeree - Starting Script"

eval HOST_IP_ADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

echo "DOCKEREE_DOWNLOAD_URL=$DOCKEREE_DOWNLOAD_URL"
echo "UCP_PUBLIC_FQDN=$UCP_PUBLIC_FQDN"
echo "UCP_ADMIN_USERID=$UCP_ADMIN_USERID"
echo "DTR_PUBLIC_FQDN=$DTR_PUBLIC_FQDN"
echo "HOST_IP_ADDRESS=$HOST_IP_ADDRESS"
echo "AZURE_TENANT_ID=$AZURE_TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID"
echo "AZURE_CLIENT_ID=$AZURE_CLIENT_ID"
echo "AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET"
echo "RGNAME=$RGNAME"
echo "LOCATION=$LOCATION"

install_docker()
{

# UBUNTU

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL ${DOCKEREE_DOWNLOAD_URL}/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 6D085F96
sudo add-apt-repository "deb [arch=amd64] ${DOCKEREE_DOWNLOAD_URL}/ubuntu $(lsb_release -cs) stable-18.09"
sudo apt-get update -y
sudo apt-get install -y docker-ee=5:18.09.6~3-0~ubuntu-xenial docker-ee-cli=5:18.09.6~3-0~ubuntu-xenial containerd.io

#Firewalling
sudo ufw allow 80/tcp
sudo ufw allow 179/tcp
sudo ufw allow 4789/udp
sudo ufw allow 6444/tcp
sudo ufw allow 7946/udp
sudo ufw allow 7946/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 12376/tcp
sudo ufw allow 12378/tcp

# Create the /etc/kubernetes/azure.json
sudo mkdir /etc/kubernetes
touch /home/$UCP_ADMIN_USERID/azure.json
echo { > /home/$UCP_ADMIN_USERID/azure.json
echo "cloud": "AzurePublicCloud", >> /home/$UCP_ADMIN_USERID/azure.json
echo "tenantId": "$AZURE_TENANT_ID", >> /home/$UCP_ADMIN_USERID/azure.json
echo "subscriptionId": "$AZURE_SUBSCRIPTION_ID", >> /home/$UCP_ADMIN_USERID/azure.json
echo "aadClientId": "$AZURE_CLIENT_ID", >> /home/$UCP_ADMIN_USERID/azure.json
echo "aadClientSecret": "$AZURE_CLIENT_SECRET", >> /home/$UCP_ADMIN_USERID/azure.json
echo "resourceGroup": "$RGNAME", >> /home/$UCP_ADMIN_USERID/azure.json
echo "location": "$LOCATION", >> /home/$UCP_ADMIN_USERID/azure.json
echo "subnetName": "/docker", >> /home/$UCP_ADMIN_USERID/azure.json
echo "securityGroupName": "ucpManager-nsg", >> /home/$UCP_ADMIN_USERID/azure.json
echo "vnetName": "clusterVirtualNetwork", >> /home/$UCP_ADMIN_USERID/azure.json
echo "primaryAvailabilitySetName": "clusterAvailabilitySet", >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderBackoff": false, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderBackoffRetries": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderBackoffExponent": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderBackoffDuration": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderBackoffJitter": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderRatelimit": false, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderRateLimitQPS": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "cloudProviderRateLimitBucket": 0, >> /home/$UCP_ADMIN_USERID/azure.json
echo "useManagedIdentityExtension": false, >> /home/$UCP_ADMIN_USERID/azure.json
echo "useInstanceMetadata": true >> /home/$UCP_ADMIN_USERID/azure.json
echo } >> /home/$UCP_ADMIN_USERID/azure.json
sudo mv /home/$UCP_ADMIN_USERID/azure.json /etc/kubernetes/

# Post Installation configuration (all Linux distros)

groupadd docker
usermod -aG docker $USER
usermod -aG docker $UCP_ADMIN_USERID

systemctl enable docker
systemctl start docker
}

install_docker;

echo $(date) " linux-install-dockeree - End of Script"
