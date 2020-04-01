#!/bin/bash
# https://xaviergeerinck.com/azure-automated-container-push
# https://docs.docker.com/install/linux/docker-ce/centos/
CONTAINER_REGISTRY_NAME=zif4test
ACR_PASSWORD=0jgrcPhzCrhYT3yCf4/s67xzKn1WJxA8
DOCKER_IMAGE_JOBMANAGER=jobmanager
DOCKER_IMAGE_TASKMANAGER=taskmanager

# check if docker is installed or not
if ! type "docker" > /dev/null; then
    echo "[Docker] Docker not installed, installing..."
    # TODO need to add sudo if not performing with root user.
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo yum install -y docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi
echo "[Docker] Logging in"
# Note: use sh -c since bash interprets it wrong and will fail to login
sudo docker login -u $CONTAINER_REGISTRY_NAME -p $ACR_PASSWORD $CONTAINER_REGISTRY_NAME.azurecr.io
echo "[AZ-ACR] Pulling JOBMANAGER container"
sudo docker pull "$CONTAINER_REGISTRY_NAME.azurecr.io/$DOCKER_IMAGE_JOBMANAGER"

echo "[AZ-ACR] Pulling TASKMANAGER container"
sudo docker pull "$CONTAINER_REGISTRY_NAME.azurecr.io/$DOCKER_IMAGE_TASKMANAGER"
echo "Making the Docker compose/containers up"
sudo docker-compose up -d
echo "Get the JOBMANAGER_Container id"
JOBMANAGER_CONTAINER=$(sudo docker ps --filter name=jobmanager --format={{.ID}})

echo "the container id is : $JOBMANAGER_CONTAINER"
echo "Copy the streaming Job to the flink jobmanager container"
sudo docker cp ./mvn-flinkstreaming-scala-1.0.jar "$JOBMANAGER_CONTAINER":/job.jar

echo "Start the Streaming Job"

sudo docker exec -t -i "$JOBMANAGER_CONTAINER" flink run /job.jar




