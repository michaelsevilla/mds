#!/bin/bash

DIR=`pwd`
CONFIG="$DIR/config/cluster.sh"
ROOTDIR=`dirname $DIR`
SCRIPTS="$ROOTDIR/scripts"
source $CONFIG

echo
echo "-----------------------------"
echo "--- START MONITORING THE CLUSTER using CONFIG=$CONFIG"
echo "-----------------------------"
$SCRIPTS/ssh-all.sh MONs $CONFIG "$SCRIPTS/dump-daemon.sh mon $CONFIG"
$SCRIPTS/ssh-all.sh MDSs $CONFIG "$SCRIPTS/dump-daemon.sh mds $CONFIG"
$SCRIPTS/ssh-all.sh OSDs $CONFIG "$SCRIPTS/dump-daemon.sh osd $CONFIG"
$SCRIPTS/ssh-all.sh CLIENTs $CONFIG "$SCRIPTS/dump-daemon.sh client $CONFIG"
$SCRIPTS/ssh-all.sh MDSs $CONFIG \
    "sudo lttng destroy; \
     sudo lttng create -o $OUT/lttng_traces; \
     sudo lttng enable-event -u --tracepoint \"mds:req*\"; \
     sudo lttng add-context -u -t pthread_id; \
     sudo lttng start"

echo
echo "-----------------------------"
echo "--- START CLIENT"
echo "-----------------------------"
$SCRIPTS/ssh-all.sh CLIENTs $CONFIG \
    "(sudo ceph-fuse /mnt/cephfs -d) > /mnt/vol2/msevilla/ceph-logs/client/client$CLIENT 2>&1"
$SCRIPTS/ssh-all.sh CLIENTs $CONFIG \
    "sudo chown -R msevilla:msevilla /mnt/cephfs"

JOB="/user/msevilla/programs/mdtest/mdtest -F -C -n 100 -d /mnt/cephfs/dir5; sleep 20"
echo 
echo "-----------------------------"
echo "--- RUN THE JOB: $JOB"
echo "-----------------------------"
$SCRIPTS/ssh-all.sh CLIENTs $CONFIG \
    "$JOB" blocking


echo 
echo "-----------------------------"
echo "--- DESTROYING LTTNG"
echo "-----------------------------"
$SCRIPTS/ssh-all.sh MDSs $CONFIG "sudo /usr/bin/lttng stop"


