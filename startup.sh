#!/bin/bash
export BASE_DIRECTORY="/home/sbruce1/Desktop/Work/Projects/Git/ICE/kdb-tick"
export ON_DISK_HDB="/home/sbruce1/Desktop/Work/Projects/Git/ICE/kdb-tick/OnDiskDB/"
export TICK_DIRECTORY="/home/sbruce1/Desktop/Work/Projects/Git/ICE/kdb-tick/tick/"

cd $BASE_DIRECTORY
q tick.q sym $ON_DISK_HDB -p 5000 &
q hdb.q $ON_DISK_HDB -p 5002 &

cd $TICK_DIRECTORY
q r.q localhost:5000 localhost:5002 -p 5008 &

#cd $BASE_DIRECTORY
#q feedhandler.q -p 5008 
