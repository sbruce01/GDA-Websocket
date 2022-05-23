#!/bin/bash

BASE_DIRECTORY=$(cd $(dirname $0) && pwd)
# Checking if directories exist

if [ ! -d $BASE_DIRECTORY/OnDiskDB ]
then
    echo "Creating On Disk DB ${BASE_DIRECTORY}/OnDiskDB"
    mkdir -p ${BASE_DIRECTORY}/OnDiskDB
fi
ON_DISK_HDB=${BASE_DIRECTORY}/OnDiskDB/
if [ ! -d ${ON_DISK_HDB}sym/ ]
then
    echo "Creating On Disk DB ${ON_DISK_HDB}sym/"
    mkdir -p ${ON_DISK_HDB}sym/
fi
if [ ! -d ${BASE_DIRECTORY}/logs/ ]
then
    echo "Creating logs directory ${BASE_DIRECTORY}/logs/"
    mkdir -p ${BASE_DIRECTORY}/logs/
fi
HDB_STARTUP_DIR=${ON_DISK_HDB}sym/
TICK_DIRECTORY=${BASE_DIRECTORY}/tick/
LOG_DIRECTORY=${BASE_DIRECTORY}/logs

cd $BASE_DIRECTORY
q tick.q sym $ON_DISK_HDB -p 5000 -t 200 > ${LOG_DIRECTORY}/tp.log 2>&1 &
q hdb.q $HDB_STARTUP_DIR -p 5002 &

cd $TICK_DIRECTORY
q r.q localhost:5000 localhost:5002 -p 5008 &
q chainedr.q localhost:5000 -p 5112 > ${LOG_DIRECTORY}/chainedr.log 2>&1 &
q wschaintick_0.2.2.q localhost:5000 -p 5110 -t 1000 > ${LOG_DIRECTORY}/wschaintick.log 2>&1 & 
q gw.q localhost:5002 localhost:5008 -p 5005 > ${LOG_DIRECTORY}/gw.log 2>&1 &

cd $BASE_DIRECTORY
q feedhandler_gda.q -p 5111 > ${LOG_DIRECTORY}/feedhandler.log 2>&1 &
