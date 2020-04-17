#!/bin/bash

echo -e "Updating config file for kafka Mongo sync"

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

CONFIG_MONGO_PROP_FILE=/opt/kafka/config/connect-standalone-mongo.properties

sed -i "s~kafka:9092~${ip4}:9092~" $CONFIG_MONGO_PROP_FILE