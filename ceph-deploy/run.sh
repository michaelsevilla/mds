#!/bin/bash

DIR=`pwd`
CONFIG="$DIR/config/cluster.sh"
ROOTDIR=`dirname $DIR`
SCRIPTS="$ROOTDIR/scripts"
source $CONFIG

echo "--- START MONITORING THE CLUSTER using CONFIG=$CONFIG"
for MON in $MONs; do
    CMD="$SCRIPTS/dump-daemon.sh mon $CONFIG"
    echo "... issdm-$MON: $CMD"
    #ssh -f issdm-$MON "$CMD"
done
for MDS in $MDSs; do
    CMD="$SCRIPTS/dump-daemon.sh mds $CONFIG"
    echo "... issdm-$MDS: $CMD"
    #ssh -f issdm-$MDS "$CMD"
done
for OSD in $OSDs; do 
    CMD="$SCRIPTS/dump-daemon.sh osd $CONFIG"
    echo "... issdm-$OSD: $CMD"
    #ssh -f issdm-$OSD "$CMD"
done

echo "--- STARTING LTTNG"
for MDS in $MDSs; do
    CMD="$SCRIPTS/start_lttng.sh"
    echo "... issdm-$MDS: $CMD"
    #ssh -f issdm-$MDS "$CMD"
done

echo "--- START CLIENT"
for CLIENT in $CLIENTs; do
    CMD="$
done

echo "--- DESTROYING LTTNG"
for MDS in $MDSs; do
    CMD="/usr/bin/lttng stop"
    echo "... issdm-$MDS: $CMD"
    #ssh -f issdm-$MDS "$CMD"
done


