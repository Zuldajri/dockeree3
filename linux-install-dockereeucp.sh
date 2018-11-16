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

eval HOST_IP_ADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

echo "HOST_IP_ADDRESS=$HOST_IP_ADDRESS"

install_docker()
{

# UBUNTU

sudo apt-get install -y apt-transport-https curl software-properties-common
curl -fsSL ${DOCKEREE_DOWNLOAD_URL}/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] ${DOCKEREE_DOWNLOAD_URL}/ubuntu $(lsb_release -cs) stable-17.06"
sudo apt-get update -y
sudo apt-get install -y docker-ee=3:18.03.1~ee~2~3-0~ubuntu

# Post Installation configuration (all Linux distros)

groupadd docker
usermod -aG docker $USER
usermod -aG docker $UCP_ADMIN_USERID

systemctl enable docker
systemctl start docker
}

install_docker;

touch /home/$UCP_ADMIN_USERID/docker_subscription.lic
echo $DOCKER_SUBSCRIPTION > /home/$UCP_ADMIN_USERID/docker_subscription.lic

chmod 777 /home/$UCP_ADMIN_USERID/docker_subscription.lic

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
    docker/ucp:3.0.6 install \
    --controller-port $UCP_PORT \
    --host-address eth0 \
    --san $CLUSTER_SAN \
    --san $UCP_SAN \
    --admin-username $UCP_ADMIN_USERID \
    --admin-password $UCP_ADMIN_PASSWORD \
    --license "$(cat /home/$UCP_ADMIN_USERID/docker_subscription.lic)" \
    --debug

# Add the Azure Storage Volume Driver

docker plugin install --alias cloudstor:azure \
  --grant-all-permissions docker4x/cloudstor:17.06.1-ce-azure1  \
  CLOUD_PLATFORM=AZURE \
  AZURE_STORAGE_ACCOUNT_KEY=$AZURE_STORAGE_ACCOUNT_KEY \
  AZURE_STORAGE_ACCOUNT=$AZURE_STORAGE_ACCOUNT_NAME \
  AZURE_STORAGE_ENDPOINT="core.windows.net" \
  DEBUG=1

echo $(date) " linux-install-ucp - End of Script"
