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

install_docker()
{

# CENTOS

# echo ${DOCKEREE_DOWNLOAD_URL}"/centos" > /etc/yum/vars/dockerurl
# yum install -y yum-utils device-mapper-persistent-data lvm2
# yum-config-manager \
#    --add-repo \
#    ${DOCKEREE_DOWNLOAD_URL}/centos/docker-ee.repo

# yum makecache fast
# yum install -y docker-ee

# UBUNTU

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL ${DOCKEREE_DOWNLOAD_URL}/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 6D085F96
sudo add-apt-repository "deb [arch=amd64] ${DOCKEREE_DOWNLOAD_URL}/ubuntu $(lsb_release -cs) stable-18.09"
sudo apt-get update -y
sudo apt-get install -y docker-ee=5:18.09.0~3-0~ubuntu-xenial

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


iptables -t nat -A POSTROUTING -m iprange ! --dst-range 168.63.129.16 -m
addrtype ! --dst-type local ! -d 10.0.0.0/16 -j MASQUERADE

# Post Installation configuration (all Linux distros)

groupadd docker
usermod -aG docker $USER
usermod -aG docker $UCP_ADMIN_USERID

systemctl enable docker
systemctl start docker
}

install_docker;

echo $(date) " linux-install-dockeree - End of Script"
