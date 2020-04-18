
#!/bin/sh

### this file will be pushed along with the image
### update _config.sh will be called from the mongo sync script
###

echo -e "Updating config file for kafka Mongo sync"
KAFKA_HOME=/opt/kafka
# get the ip of the running

$(touch /tmp/test.txt)

echo "$1" > "/tmp/test.txt"

# Get the IP of the running host machine

# TODO based on any linux type, the below ip address works for Centos

ip4_mongodb=$1

# replace the strings in properties files the strings
# connection.uri=mongodb://mongo1:27017 to # connection.uri=mongodb://172.18.0.5:27017


CONFIG_MONGO_SYNC_FILE=/opt/kafka/config/connect-mongo-sink.properties

sed -i "s~mongo1:27017~${ip4_mongodb}:27017~" $CONFIG_MONGO_SYNC_FILE

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echo "IP address of the kafka container is : $ip4"

# to replace bootstrap.servers=kafka:9092 to bootstrap.servers=172.18.0.194:9092
CONFIG_MONGO_PROP_FILE=/opt/kafka/config/connect-standalone-mongo.properties

sed -i "s~kafka:9092~${ip4}:9092~" $CONFIG_MONGO_PROP_FILE

# start the sync JOB,
# TODO Need to check the logfile size and take action accordingly...

# KAFKA_SHELL_FILE=/opt/kafka/bin/connect-standalone.sh
# function sync_kafka_mongo(){

# cd /opt/kafka/

KAFKA_MONGO_OUT_FILE=/opt/kafka/kafka-mongo-info.out
KAFKA_MONGO_ERR_FILE=/opt/kafka/kafka-mongo-error.err

# $(nohup .$KAFKA_HOME/bin/connect-standalone.sh /opt/kafka/config/connect-standalone-mongo.properties \
#  /opt/kafka/config/connect-mongo-sink.properties > $KAFKA_MONGO_OUT_FILE 2> $KAFKA_MONGO_ERR_FILE \&)

declare -a parameters=("/opt/kafka/config/connect-standalone-mongo.properties" "/opt/kafka/config/connect-mongo-sink.properties" )
for parameter in "${parameters[@]}"
do
   nohup .$KAFKA_HOME/bin/connect-standalone.sh  -p $parameter 1> $KAFKA_MONGO_OUT_FILE 2> $KAFKA_MONGO_ERR_FILE &
done
