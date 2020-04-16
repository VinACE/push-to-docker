#!/bin/bash
#---------------------------------------------------------------#
#It is deployment script for custmomer where user runs this file#
#---------------------------------------------------------------#

## reference
# https://stackoverflow.com/questions/39493490/provide-static-ip-to-docker-containers-via-docker-compose
# deployAdapter.sh <zifcoreip:zifcorebroker port no>
# required for  docker reqistry login.. 
# TODO this can be done as one time...
CONTAINER_REGISTRY_NAME=zif4test
ACR_PASSWORD=0jgrcPhzCrhYT3yCf4/s67xzKn1WJxA8
# TODO write about usage...

# check for Docker installation...

# check if docker is installed or not
if ! type "docker" > /dev/null; then
    echo "[Docker] Docker not installed, installing..."
    # TODO need to add sudo if not performing with root user.
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
   
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    #sudo yum install -y docker-compose
	sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

echo "[Docker] Logging in"
# Note: use sh -c since bash interprets it wrong and will fail to login
# sudo docker login -u $CONTAINER_REGISTRY_NAME -p $ACR_PASSWORD $CONTAINER_REGISTRY_NAME.azurecr.io

# TODO based on any linux type, the below ip address works for Centos
ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echo "IP address of the machine is : $ip4"


 # TODO replace entries in the config files using SED operators
 
#TODO check yml file exists in the current directory to proceed
if [ -f kafka-mongo-sync-docker-compose.yml ]; then
COMPOSE_FILE_NAME=kafka-mongo-sync-docker-compose.yml
else
    echo -e "kafka-mongo-sync-docker-compose.yml file not found"
    exit 2
fi
echo Updating yml file for source ip

sed -i "s/SOURCE_KAFKA_IPADDRESS/${ip4}/" $COMPOSE_FILE_NAME

 # TODO replace the subnet last digits with 192.


# TODO

echo -e "End of script file ####################"