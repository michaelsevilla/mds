#!/bin/bash

DIR=`pwd`
CONFIG="$DIR/ceph-deploy/config/cluster.sh"
source $CONFIG

echo "Running job with config: $CONFIG"
echo "SCRIPTS: $SCRIPTS"
echo "--- START MONITORING THE CLUSTER"
for MON in $MONs; do
    CMD="$SCRIPTS/dump-daemon.sh mon $CONFIG"
    echo "... issdm-$MON: $CMD"
    ssh -f issdm-$MON "$CMD"
done
for MDS in $MDSs; do
    CMD="$SCRIPTS/dump-daemon.sh mds $CONFIG"
    echo "... issdm-$MDS: $CMD"
    #ssh -f issdm-$MDS "$CMD"
done
for OSD in $OSDs; do 
    CMD="$SCRIPTS/dump-daemon.sh osd $CONFIG"
    echo "... issdm-$OSD: $CMD"
    #Assh -f issdm-$OSD "$CMD"
done

wait
echo "... done"
