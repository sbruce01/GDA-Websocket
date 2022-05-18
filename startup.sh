#!/bin/bash

BASE_DIRECTORY=$(cd $(dirname $0) && pwd)
if [ ! -d $BASE_DIRECTORY/OnDiskDB ]
then
    echo "Creating On Disk DB ${BASE_DIRECTORY}/OnDiskDB"
    mkdir -p ${BASE_DIRECTORY}/OnDiskDB
fi
ON_DISK_HDB=${BASE_DIRECTORY}/OnDiskDB/
HDB_STARTUP_DIR=${ON_DISK_HDB}/sym/
TICK_DIRECTORY=${BASE_DIRECTORY}/tick/

cd $BASE_DIRECTORY
q tick.q sym $ON_DISK_HDB -p 5000 &
q hdb.q $HDB_STARTUP_DIR -p 5002 &

cd $TICK_DIRECTORY
q r.q localhost:5000 localhost:5002 -p 5008 &
q chainedr.q localhost:5000 -p 5112 > chainedr.log 2>&1 &

cd $BASE_DIRECTORY
q feedhandler_gda.q -p 5111 > allExchanges.log 2>&1 &
