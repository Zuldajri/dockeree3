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

# wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/j/jq-1.5-1.el7.x86_64.rpm

# CENTOS

#yum install -y epel-release
#yum install -y jq-1.5-1.el7.x86_64.rpm

# UBUNTU
apt-get install jq unzip -y

# Install sshpass
sudo apt-get install sshpass

# Send bundle.zip
sudo sshpass -p $UCP_ADMIN_PASSWORD scp -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4:/home/$UCP_ADMIN_USERID/bundle.zip /home/$UCP_ADMIN_USERID/bundle.zip 

# Download the user client bundle to extract the certificate and configure the cli for the swarm to join
unzip /home/$UCP_ADMIN_USERID/bundle.zip && chmod +x /var/lib/waagent/custom-script/download/0/env.sh && source /var/lib/waagent/custom-script/download/0/env.sh

# Ask the UCP Controller to give us the docker join command to execute

docker swarm join-token manager|sed '1d'|sed '1d'|sed '$ d'> /var/lib/waagent/custom-script/download/0/docker-managerswarmjoin
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH
unset DOCKER_HOST

# Execute the join

chmod +x /var/lib/waagent/custom-script/download/0/docker-managerswarmjoin
/var/lib/waagent/custom-script/download/0/docker-managerswarmjoin

echo $(date) "linux-join-swarm - End of Script"
