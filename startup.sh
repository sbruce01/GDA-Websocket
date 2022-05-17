#!/bin/bash

BASE_DIRECTORY=$(cd $(dirname $0) && pwd)
if [ ! -d $BASE_DIRECTORY/OnDiskDB ]
then
    echo "Creating On Disk DB ${BASE_DIRECTORY}/OnDiskDB"
    mkdir -p ${BASE_DIRECTORY}/OnDiskDB
fi
ON_DISK_HDB=${BASE_DIRECTORY}/OnDiskDB/
TICK_DIRECTORY=${BASE_DIRECTORY}/tick/

cd $BASE_DIRECTORY
q tick.q sym $ON_DISK_HDB -p 5000 &
q hdb.q $ON_DISK_HDB -p 5002 &

cd $TICK_DIRECTORY
q r.q localhost:5000 localhost:5002 -p 5008 &
q chainedtick.q localhost:5010 -p 5110 -t 0 &

# #cd $BASE_DIRECTORY
# #q feedhandler.q -p 5008 
