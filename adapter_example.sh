#!/bin/sh
#---------------------------------------------------------------#
#It is deployment script for custmomer where user runs this file#
#---------------------------------------------------------------#
# deployAdapter.sh <zifcoreip:zifcorebroker port no>


if [ ! -e zif-adapter-docker-compose.yml ] ; then
  if [ ! -e $ADAPTER_DOCKER_COMPOSE_FILE_PATH/zif-adapter-docker-compose.yml ] ; then
	   ls -ltr
	  echo :: WARNING :  zif-adapter-docker-compose.yml file is not found in the current directory :: $(pwd) or $ADAPTER_DOCKER_COMPOSE_FILE_PATH 	  
	  echo :: Please have all required files before proceeding !!
	 
  	  exit
  else
	cd $ADAPTER_DOCKER_COMPOSE_FILE_PATH
	
  fi

fi 


targetIp=dummyIP
isFromBashrc="false"
if [ "$#" -ne 1 ]; then

  if [[ -z "$PREV_USED_ZIFCORE_IP" ]]; then 
  	echo "Usage: $0 <ZIFCORE VALID IPADDRESS>"
  	exit 1
  else
	targetIp=$PREV_USED_ZIFCORE_IP
	isFromBashrc="true"
	composeFilePath=$ADAPTER_DOCKER_COMPOSE_FILE_PATH
  fi
else
   targetIp=$1
   composeFilePath=$(pwd)
fi


echo WARNING: It removes existing docker containers and images before proceeding.


function to_int {
    local -i num="10#${1}"
    echo "${num}"
}

function port_is_ok {
    local port="$1"
    local -i port_num=$(to_int "${zifCorePort}" 2>/dev/null)

    if (( $port_num < 1 || $port_num > 65535 )) ; then
        echo "*** ${port} is not a valid port" 1>&2
        exit 3
    fi
   
}

function removeAdapterDocker()
{
CNAME=$1 #container name
INAME=$2 #image name
if [ "$(sudo docker ps -qa -f name=$CNAME)" ]; then
    echo ":: Found container - $CNAME"
    if [ "$(sudo docker ps -q -f name=$CNAME)" ]; then
        echo ":: Stopping running container - $CNAME"
        sudo docker stop $CNAME -t 10;
		
    fi
    echo ":: Removing stopped container - $CNAME"
    sudo docker rm -f $CNAME;
fi

	sudo docker rmi -f $INAME

}

function checkAdapterinstalled()
{
local  stat=1
CNAME=$1 #container name
INAME=$2 #image name
if [ "$(sudo docker ps -qa -f name=$CNAME)" ]; then
	echo ":: Found container - $CNAME"
	if [ "$(sudo docker ps -q -f name=$CNAME -f status=running)" ]; then
		echo ":: Found container Running - $CNAME"
		stat=0
	fi	
			
fi
	return $stat
}


sourceIp=localhost

function getLocalIpAddress()
{
	sourceIp=$(
		ifconfig eth0 |
		perl -ne 'print $1 if /inet\s.*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/'
	)
}

getLocalIpAddress

function valid_ip()
{
    local  ip=$1
    local  stat=1	

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi	
    return $stat
}
function pingCheck()
{

	echo "Connection check for $1..... Please wait"
	local stat=1
	# -q quiet
	# -c nb of pings to perform

	ping -q -c5 $1 > /dev/null

	if [ $? -eq 0 ]
	then
		stat=0			
		echo "Connection success... Installation proceeds..."
	fi
	
	  return  $stat

}

function createAsService()
{

	SERVICE_PATH=/etc/systemd/system
	USR_BIN=/usr/bin
	rm -f $USR_BIN/zifAdapterService.sh

	rm -f $USR_BIN/$COMPOSE_FILE_NAME

	rm -f $SERVICE_PATH/zifadapter.service

	sudo cp deployAdapter.sh $USR_BIN/zifAdapterService.sh
	sudo chmod +x $USR_BIN/zifAdapterService.sh


	echo "[Unit]" >> $SERVICE_PATH/zifadapter.service
	echo "Description=ZIF Adapter systemd service." >> $SERVICE_PATH/zifadapter.service


	echo "[Service]" >> $SERVICE_PATH/zifadapter.service
	echo "Type=simple" >> $SERVICE_PATH/zifadapter.service
       	echo "ExecStart=/bin/bash $USR_BIN/zifAdapterService.sh" >> $SERVICE_PATH/zifadapter.service
	echo "[Install]" >> $SERVICE_PATH/zifadapter.service

	echo "WantedBy=multi-user.target" >> $SERVICE_PATH/zifadapter.service

	sudo chmod 644 $SERVICE_PATH/zifadapter.service

	sudo systemctl enable zifadapter
	
	echo Adapter created as boot service!!
	
}

function stopRunningAdapterBootService()
{
	sudo systemctl stop zifadapter
	sudo systemctl disable zifadapter

}
#TODO validate whether it always return correct ip

 if ! valid_ip $sourceIp; then
	echo $sourceIp is not valid. Kindly provide valid ip address to continue!
	exit 3
 fi




 if ! valid_ip $targetIp; then
	echo $targetIp is not valid. Kindly provide valid ip address to continue!
	exit 3
 else
	if ! pingCheck $targetIp; then
		echo $targetIp is not up or No connection is established. Kindly provide valid ip address to continue!
		exit
	fi
 fi




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

###
# Stop the ZIF adapter running service if any
###
echo :: Stopping ZIF Adapter boot services
stopRunningAdapterBootService

ADAPTER_ZK_CNAME=adapter_zookeeper
ADAPTER_ZK_INAME=zif4test.azurecr.io/zookeeper
ADAPTER_KAFKA_CNAME=adapter_kafka
ADAPTER_KAFKA_INAME=zif4test.azurecr.io/adapter_kafka


echo
echo Removing existing adapter if required and new installation starts now:
echo

removeAdapterDocker $ADAPTER_KAFKA_CNAME $ADAPTER_KAFKA_INAME
removeAdapterDocker $ADAPTER_ZK_CNAME $ADAPTER_ZK_INAME


#TODO check yml file exists in the current directory to proceed
COMPOSE_FILE_NAME=zif-adapter-docker-compose.yml


        echo Updating yml file for source ip

        sed -i "s/SOURCE_KAFKA_IPADDRESS/${sourceIp}/" $COMPOSE_FILE_NAME

        #echo Pulling adapter required docker images from yml file

        #KAFKA_ADVERTISED_HOST_NAME=$sourceIp docker-compose up -d

        echo Starting adapter containers to be running.

        sudo docker-compose --file $COMPOSE_FILE_NAME up -d
		
		#TODO check kafka/zookeeper is running		
                counter=0
		isRunning="true"
		while [ $counter -le 5 ]
		do

				if ! checkAdapterinstalled $ADAPTER_ZK_CNAME $ADAPTER_ZK_INAME; then
						echo Adapter zookeeper is either not running or not installed properly. Please wait until further check
						isRunning="false"
						sleep 10
				else
						isRunning="true"
						if ! checkAdapterinstalled $ADAPTER_KAFKA_CNAME $ADAPTER_KAFKA_INAME; then
								echo Adapter zookeeper is either not running or installed properly
								isRunning="false"
								sleep 10
						fi
				fi
				if [ $isRunning == "true" ]; then
					counter=6
				fi
				(( counter++ ))
		done

		if [ $isRunning == "true" ]; then
			
			echo ::  Adapter is almost installed !!! few more steps to be completed!!
			ZIF_ADAPTER_KAFKA_CONTAINER=$(sudo docker ps --filter name=$ADAPTER_KAFKA_CNAME --format={{.ID}})
			sudo docker exec -d -it "$ZIF_ADAPTER_KAFKA_CONTAINER" /bin/bash ./opt/kafka/zifAdapterMirror.sh $sourceIp $targetIp
echo :: Adapter Mirroring execut			ed...
			sudo docker ps -a	
			
			grep PREV_USED_ZIFCORE_IP ~/.bashrc
				if [ $? -eq 0 ] ; then
					sed -i "s/^export PREV_USED_ZIFCORE_IP=.*/export PREV_USED_ZIFCORE_IP=$targetIp/" ~/.bashrc
					sed -i "s/^export ADAPTER_DOCKER_COMPOSE_FILE_PATH.*/export ADAPTER_DOCKER_COMPOSE_FILE_PATH=$composeFilePath/" ~/.bashrc
					
				else
					echo "export ADAPTER_DOCKER_COMPOSE_FILE_PATH=$composeFilePath" >> ~/.bashrc
					echo "export PREV_USED_ZIFCORE_IP=$targetIp" >> ~/.bashrc
						
				fi
    			createAsService
			sed -i "s/${sourceIp}/SOURCE_KAFKA_IPADDRESS/" $COMPOSE_FILE_NAME
			echo   " "
			echo   :: Adapter installed successfully!!
			unset PREV_USED_ZIFCORE_IP
			unset ADAPTER_DOCKER_COMPOSE_FILE_PATH
			exit 0

		else
			echo :: Adapter installation failed......
			exit
		fi
