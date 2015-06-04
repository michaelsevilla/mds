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

JOB="mpirun --mca btl_tcp_if_include eth1 --host issdm-5 /user/msevilla/programs/mdtest/mdtest -n 100000 -F -C -d /mnt/cephfs/shared"
echo 
echo "-----------------------------"
echo "--- RUN THE JOB: $JOB"
echo "-----------------------------"
eval $JOB > /mnt/vol2/msevilla/ceph-logs/client/clients.log 2>&1

echo 
echo "-----------------------------"
echo "--- DESTROYING LTTNG"
echo "-----------------------------"
$SCRIPTS/ssh-all.sh MDSs $CONFIG "sudo /usr/bin/lttng stop"


