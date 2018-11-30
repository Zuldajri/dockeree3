#!/bin/bash
#
# Parameters required for the script
#
# UCP_PUBLIC_FQDN : UCP Public URL
# UCP_ADMIN_USERID : The UCP Admin user ID (also the ID of the Linux Administrator)
# UCP_ADMIN_PASSWORD : Password of the UCP administrator
# DTR_PUBLIC_FQDN : DTR Public URL

echo $(date) " linux-install-dtr - Starting Script"

echo "UCP_PUBLIC_FQDN=$UCP_PUBLIC_FQDN"
echo "DTR_PUBLIC_FQDN=$DTR_PUBLIC_FQDN"
echo "UCP_ADMIN_USERID=$UCP_ADMIN_USERID"
echo "UCP_ADMIN_PASSWORD=<Not Copied for obvious security reasons"

echo $(date) " linux-install-dtr - Waiting for node registration to complete"
sleep 4m
echo $(date) " linux-install-dtr - Now start the DTR installation"

#eval HOST_IP_ADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
#echo "HOST_IP_ADDRESS=$HOST_IP_ADDRESS"

#install DTR

docker run --rm docker/dtr:2.6.0 install \
      --ucp-url $UCP_PUBLIC_FQDN \
      --ucp-node "dtrmanager" \
      --dtr-external-url $DTR_PUBLIC_FQDN \
      --ucp-username $UCP_ADMIN_USERID \
      --ucp-password $UCP_ADMIN_PASSWORD \
      --ucp-insecure-tls \
#      --replica-https-port 444 \
#      --replica-http-port 84 \
--debug

echo "address 10.0.2.4" >> /etc/network/interfaces.d/50-cloud-init.cfg
echo "netmask 10.0.0.0/16" >> /etc/network/interfaces.d/50-cloud-init.cfg

sudo ifdown eth0 && sudo ifup eth0

# Install sshpass
#sudo apt-get install sshpass
#sudo sshpass -p $UCP_ADMIN_PASSWORD ssh -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4 "$(UCP_ADMIN_USERID=williamm && docker node ls | grep linuxWorker1 | awk 'NR==1 {print $1}' > /home/$UCP_ADMIN_USERID/linuxWorker1ID)"
#sudo sshpass -p $UCP_ADMIN_PASSWORD ssh -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4 "$(UCP_ADMIN_USERID=williamm && docker node ls | grep linuxWorker2 | awk 'NR==1 {print $1}' > /home/$UCP_ADMIN_USERID/linuxWorker2ID)"
#sudo sshpass -p $UCP_ADMIN_PASSWORD ssh -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4 "$(UCP_ADMIN_USERID=williamm && docker node ls | grep dtrmanager | awk 'NR==1 {print $1}' > /home/$UCP_ADMIN_USERID/dtrManagerID)"


#sudo sshpass -p $UCP_ADMIN_PASSWORD ssh -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4 "$(UCP_ADMIN_USERID=williamm && docker node update --label-add com.docker.ucp.orchestrator.kubernetes=true "$(cat /home/$UCP_ADMIN_USERID/linuxWorker1ID)")"
#sudo sshpass -p $UCP_ADMIN_PASSWORD ssh -o StrictHostKeyChecking=No $UCP_ADMIN_USERID@10.0.1.4 "$(UCP_ADMIN_USERID=williamm && docker node update --label-add com.docker.ucp.orchestrator.swarm=false "$(cat /home/$UCP_ADMIN_USERID/linuxWorker1ID)")"

echo $(date) " linux-install-dtr - End of Script"
