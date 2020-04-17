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
    sudo yum install -y containerd.io docker-ce-cli containerd.io
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    #sudo yum install -y docker-compose
	sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

#TODO Need to check whether there need to reassign the shell for docker commands to pick..
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

 # TODO replace the subnet last digits with 192.


# identify the subnet of the network...

default_if=$(ip route list | awk '/^default/ {print $5}')
network_subnet=$(ip -o -f inet addr show $default_if | awk '{print $4}')

echo -e "Network subnet is :$network_subnet"

str=$network_subnet
newstr=$(awk -F"." '{print $1"."$2"."$3".192/26"}'<<<$str)

new_subnet=$newstr

echo "new subnet is $new_subnet"

newstr1=$(awk -F"." '{print $1"."$2"."$3".194"}'<<<$str)
kafka_ip=$newstr1

echo "new ip fo Kafka is $kafka_ip"

# TODO check the IP address are already used in the network...***********

        echo -e "Updating yml file for  ip and subnet "

        sed -i "s~KAFKA_SUBNET~${new_subnet}~" $COMPOSE_FILE_NAME
        sed -i "s~KAFKA_IPADDRESS~${kafka_ip}~" $COMPOSE_FILE_NAME


echo Starting kafka containers to be running.


$(docker-compose --file $COMPOSE_FILE_NAME up -d)
sleep 30
KAFKA_CNAME=kafka_mongo_sync

KAFKA_CONTAINER=$(docker ps --filter name=$KAFKA_CNAME --format={{.ID}})

$(docker exec  -it -d "$KAFKA_CONTAINER" /bin/bash  -c "/opt/kafka/update_config.sh $ip4")



echo $KAFKA_CONTAINER
# $(cd /opt/kafka/config/)
# echo "$(pwd)"
# connect_mongo_sink_file=connect-mongo-sink.properties








		


# ZIF_ADAPTER_KAFKA_CONTAINER=$(sudo docker ps --filter name=$ADAPTER_KAFKA_CNAME --format={{.ID}})

# TODO


echo -e "End of script file ####################"

# TODO check the IP address are already used in the network...***********


# TODO to stop command for the container...



