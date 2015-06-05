#!/bin/bash
CONFIG=`readlink -f ./config/cluster.sh`
CONFIGDIR=`dirname $CONFIG`
DEPLOYDIR=`dirname $CONFIGDIR`
ROOTDIR=`dirname $DEPLOYDIR`
SCRIPTS="$ROOTDIR/scripts"
source $CONFIG


JOB="./stop-cluster.sh $CONFIG /tmp/blah reset"
echo "-----------------------------"
echo "--- CLEANUP: $JOB"
echo "-----------------------------"
eval $JOB

for i in {0..2}; do
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
    
    TARGETS=""
    COUNT=0
    for i in $CLIENTs; do
        if [ $COUNT -eq 0 ]; then
            TARGETS="$i"
        else
            TARGETS="$TARGETS,$i"
        fi
        COUNT=$(($COUNT+1))
    done
    echo $TARGETS
    JOB="mpirun --mca btl_tcp_if_include eth1 --host $TARGETS /user/msevilla/programs/mdtest/mdtest -n 100000 -F -C -d /mnt/cephfs/shared"
    echo 
    echo "-----------------------------"
    echo "--- RUN THE JOB: $JOB"
    echo "-----------------------------"
    eval $JOB > $OUT/client/clients.log 2>&1
    cat $OUT/client/clients.log
    
    echo 
    echo "-----------------------------"
    echo "--- DESTROYING LTTNG"
    echo "-----------------------------"
    $SCRIPTS/ssh-all.sh MDSs $CONFIG "sudo /usr/bin/lttng stop"

    JOB="./stop-cluster.sh $CONFIG $NFSOUT/run$i reset"
    echo 
    echo "-----------------------------"
    echo "--- RESET: $JOB"
    echo "-----------------------------"
    eval $JOB
    rm -r $NFSOUT/run$i
    sleep 10
done
