#!/bin/bash
#
#
# Parameters
#
# UCP_PUBLIC_FQDN : UCP Public URL
# UCP_ADMIN_USERID : The UCP Admin user ID (also the ID of the Linux Administrator)
# UCP_ADMIN_PASSWORD : Password of the UCP administrator

echo $(date) "linux-join-swarm - Starting Script"

echo "UCP_PUBLIC_FQDN=$UCP_PUBLIC_FQDN"
echo "UCP_ADMIN_USERID=$UCP_ADMIN_USERID"
echo "UCP_ADMIN_PASSWORD=<Not Copied for obvious security reasons"

# Get necessary packages to process the UCP Auth Token

# UBUNTU

apt-get install jq unzip -y

# Retrieve and extract the Auth Token for the current user

AUTHTOKEN=$(curl -sk -d '{"username":"'"$UCP_ADMIN_USERID"'","password":"'"$UCP_ADMIN_PASSWORD"'"}' https://$UCP_PUBLIC_FQDN/auth/login | jq -r .auth_token)
echo "AUTH TOKEN IS : $AUTHTOKEN"

# Download the user client bundle to extract the certificate and configure the cli for the swarm to join

curl -k -H "Authorization: Bearer ${AUTHTOKEN}" https://$UCP_PUBLIC_FQDN/api/clientbundle -o bundle.zip
unzip bundle.zip && chmod +x env.sh && source env.sh

# Ask the UCP Controller to give us the docker join command to execute

docker swarm join-token worker|sed '1d'|sed '1d'|sed '$ d'> ./docker-workerswarmjoin
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH
unset DOCKER_HOST

# Execute the join

chmod +x ./docker-workerswarmjoin
./docker-workerswarmjoin

echo $(date) "linux-join-swarm - End of Script"
