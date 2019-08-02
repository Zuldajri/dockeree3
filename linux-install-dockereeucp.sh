#!/bin/bash
#
#
# Parameters
# DOCKEREE_DOWNLOAD_URL : Base location of the Docker EE packages
# UCP_PUBLIC_FQDN : UCP Public URL
# UCP_ADMIN_USERID : The UCP Admin user ID (also the ID of the Linux Administrator)
# UCP_ADMIN_PASSWORD : Password of the UCP administrator
# DTR_PUBLIC_FQDN : DTR Public URL

echo $(date) " linux-install-dockereeucp - Starting Script"


AZURE_STORAGE_ACCOUNT_NAME=$1
AZURE_STORAGE_ACCOUNT_KEY=$2
UCP_PUBLIC_FQDN=$3
DOCKER_SUBSCRIPTION="$4"
CLUSTER_SAN=$5
DTR_PUBLIC_FQDN=$6
UCP_ADMIN_USERID=$7
UCP_ADMIN_PASSWORD=$8
DOCKEREE_DOWNLOAD_URL=$9
AZURE_CLIENT_ID=${10}
AZURE_TENANT_ID=${11}
AZURE_SUBSCRIPTION_ID=${12}
AZURE_CLIENT_SECRET="${13}"
LOCATION=${14}
RGNAME=${15}
PRIVATEKEY=${16}

# Generate private keys for use 
echo $(date) " - Generating Private keys for SWARM Installation"

runuser -l $UCP_ADMIN_USERID -c "echo -e \"$PRIVATEKEY\" > ~/.ssh/id_rsa"
runuser -l $UCP_ADMIN_USERID -c "chmod 600 ~/.ssh/id_rsa*"

eval HOST_IP_ADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

echo "HOST_IP_ADDRESS=$HOST_IP_ADDRESS"

install_docker()
{

# UBUNTU

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL ${DOCKEREE_DOWNLOAD_URL}/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 6D085F96
sudo add-apt-repository "deb [arch=amd64] ${DOCKEREE_DOWNLOAD_URL}/ubuntu $(lsb_release -cs) stable-19.03"
sudo apt-get update -y
sudo apt-get install -y docker-ee=5:19.03.1~3-0~ubuntu-xenial docker-ee-cli=5:19.03.1~3-0~ubuntu-xenial containerd.io

# Post Installation configuration (all Linux distros)

groupadd docker
usermod -aG docker $USER
usermod -aG docker $UCP_ADMIN_USERID

systemctl enable docker
systemctl start docker
}

install_docker;

# Set the Kubernetes version as found in the UCP Dashboard or API
k8sversion=v1.14.3
# Get the kubectl binary.
curl -LO https://storage.googleapis.com/kubernetes-release/release/$k8sversion/bin/linux/amd64/kubectl
# Make the kubectl binary executable.
chmod +x ./kubectl
# Move the kubectl executable to /usr/local/bin.
sudo mv ./kubectl /usr/local/bin/kubectl

# Azure - GET PODCIDR & Set up Route Table
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv --keyserver packages.microsoft.com --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
sudo apt-get update
sudo apt-get install azure-cli

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

#PRIVATE_IP_ADDRESS=$(az vm show -d -g $RGNAME -n linuxWorker1 --query "privateIps" -otsv)
POD_CIDR=10.0.0.0/16

# Create the /etc/kubernetes/azure.json
#echo "routeTableName": "kubernetes-route-podcidr", >> /home/$UCP_ADMIN_USERID/azure.json
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


# Create the docker_subscription.lic
touch /home/$UCP_ADMIN_USERID/docker_subscription.lic
echo $DOCKER_SUBSCRIPTION > /home/$UCP_ADMIN_USERID/docker_subscription.lic

chmod 777 /home/$UCP_ADMIN_USERID/docker_subscription.lic
  
wget https://packages.docker.com/caas/ucp_images_3.2.0.tar.gz -O ucp.tar.gz
docker load < ucp.tar.gz

#Firewalling
sudo ufw allow 179/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2376/tcp
sudo ufw allow 2377/tcp
sudo ufw allow 4789/udp
sudo ufw allow 6443/tcp
sudo ufw allow 6444/tcp
sudo ufw allow 7946/udp
sudo ufw allow 7946/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 12376/tcp
sudo ufw allow 12378/tcp
sudo ufw allow 12379/tcp
sudo ufw allow 12380/tcp
sudo ufw allow 12381/tcp
sudo ufw allow 12382/tcp
sudo ufw allow 12383/tcp
sudo ufw allow 12384/tcp
sudo ufw allow 12385/tcp
sudo ufw allow 12386/tcp
sudo ufw allow 12387/tcp
sudo ufw allow 12388/tcp

# Split the UCP FQDN et get the SAN and the port

UCP_SAN=${UCP_PUBLIC_FQDN%%:*}
UCP_PORT=${UCP_PUBLIC_FQDN##*:}

if [ "$UCP_PORT" = "$UCP_PUBLIC_FQDN" ]
   then
     UCP_PORT="443"
fi

echo "UCP_SAN=$UCP_SAN"
echo "UCP_PORT=$UCP_PORT"

# Install UCP
docker run --rm -i --name ucp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    docker/ucp:3.2.0 install \
    --san $CLUSTER_SAN \
    --san $UCP_SAN \
    --host-address 10.0.1.4 \
    --admin-username $UCP_ADMIN_USERID \
    --admin-password $UCP_ADMIN_PASSWORD \
    --pod-cidr 10.0.0.0/16 \
    --cloud-provider Azure \
    --license "$(cat /home/$UCP_ADMIN_USERID/docker_subscription.lic)" \
    --debug


# Add the Azure Storage Volume Driver

docker plugin install --alias cloudstor:azure \
  --grant-all-permissions docker4x/cloudstor:19.03.0-ce-azure1  \
  CLOUD_PLATFORM=AZURE \
  AZURE_STORAGE_ACCOUNT_KEY=$AZURE_STORAGE_ACCOUNT_KEY \
  AZURE_STORAGE_ACCOUNT=$AZURE_STORAGE_ACCOUNT_NAME \
  AZURE_STORAGE_ENDPOINT="core.windows.net" \
  DEBUG=1

# UBUNTU

apt-get install jq unzip -y

# Retrieve and extract the Auth Token for the current user

AUTHTOKEN=$(curl -sk -d '{"username":"'"$UCP_ADMIN_USERID"'","password":"'"$UCP_ADMIN_PASSWORD"'"}' https://$UCP_PUBLIC_FQDN/auth/login | jq -r .auth_token)
echo "AUTH TOKEN IS : $AUTHTOKEN"

# Download the user client bundle to extract the certificate and configure the cli for the swarm to join
curl -k -H "Authorization: Bearer ${AUTHTOKEN}" https://$UCP_PUBLIC_FQDN/api/clientbundle -o /home/$UCP_ADMIN_USERID/bundle.zip
unzip /home/$UCP_ADMIN_USERID/bundle.zip && chmod +x /var/lib/waagent/custom-script/download/0/env.sh && source /var/lib/waagent/custom-script/download/0/env.sh

kubectl create -f https://raw.githubusercontent.com/Zuldajri/DockerEE/master/nfs-server.yaml
sleep 2m

IP=$(kubectl describe pod nfs-server | grep IP: | awk 'NR==1 {print $2}')

wget https://raw.githubusercontent.com/Zuldajri/DockerEE/master/default-storage.yaml -O /home/$UCP_ADMIN_USERID/default-storage.yaml
echo "  server": "$IP" >> /home/$UCP_ADMIN_USERID/default-storage.yaml
kubectl create -f /home/$UCP_ADMIN_USERID/default-storage.yaml

echo $(date) " linux-install-ucp - End of Script"
