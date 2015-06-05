#!/bin/bash

if [ $# -lt 3 ]; then
    echo -e "USAGE: $0 <config> <output dir> <reset|stop|teardow>"
    echo -e "Options:"
    echo -e "\t config:     configuration file for the cluster"
    echo -e "\t output dir: where to put the ceph logs"
    echo -e "\t reset:      delete the data"
    echo -e "\t stop:       stop collectl, unmount clients, copy logs"
    echo -e "\t teardown:   stop all Ceph daemons and delete data"
    exit
fi
CONFIG=$1
source $CONFIG
NFSOUT=$2
CMD=$3
CONFDIR=`dirname $CONFIG`
DEPLOYDIR=`dirname $CONFDIR`
ROOTDIR=`dirname $DEPLOYDIR`
SCRIPTS="$ROOTDIR/scripts"

echo "==================="
echo "Command:           $CMD"
echo "NFS directory:     $NFSOUT"
echo "Root directory:    $ROOTDIR"
echo "Root directory:    $CONFDIR"
echo "Deploy directory:  $DEPLOYDIR"
echo "Scripts directory: $SCRIPTS"
echo "==================="

mkdir -p    $NFSOUT/osd/perf $NFSOUT/osd/cpu \
            $NFSOUT/mds/perf $NFSOUT/mds/cpu $NFSOUT/mds/lttng_traces \
            $NFSOUT/mon $NFSOUT/config $NFSOUT/client $NFSOUT/dump-daemons > /dev/null 2>&1

if [ "$cmd" == "teardown" ]; then
    echo -n "I'm about to tear down the Ceph cluster, are you sure [y/n]? "
    read teardown
    if [ "$teardown" == "n" ]; then
        exit
    fi
fi

if [ "$CMD" == "teardown" ] || [ "$CMD" == "stop" ] || [ "$CMD" == "reset" ]; then
    echo "... umounting..."
    UMOUNT="sudo umount /mnt/cephfs > /dev/null 2>&1"
    UMOUNT="$UMOUNT; sudo pkill ceph-fuse"
    UMOUNT="$UMOUNT; $SCRIPTS/cleanup.sh client"
    $SCRIPTS/ssh-all.sh CLIENTs $CONFIG "$UMOUNT" blocking
    
    echo "... copying logs"
    COPY="sudo chown -R msevilla:msevilla $OUT"
    COPY="$COPY; cp -r $OUT/* $NFSOUT/"
    COPY="$COPY; sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/"
    $SCRIPTS/ssh-all.sh MDSs $CONFIG "$COPY" blocking
    $SCRIPTS/ssh-all.sh OSDs $CONFIG "$COPY" blocking
    $SCRIPTS/ssh-all.sh CLIENTs $CONFIG "$COPY" blocking
    COPY="$COPY; sudo cp /etc/ceph/ceph.conf $NFSOUT/config/ceph.conf"
    $SCRIPTS/ssh-all.sh MONs $CONFIG "$COPY" blocking

    echo "... killing collectl, deleting logs"
    KILL="sudo pkill collectl"
    KILL="$KILL; ps ax | grep dump | grep -v greph | awk '{print \$1}' | while read p; do sudo kill -9 \$p; done"
    KILL="$KILL; rm -r $OUT/* > /dev/null 2>&1"
    $SCRIPTS/ssh-all.sh ALL $CONFIG "$KILL" blocking >> /dev/null 2>&1

    echo "... tarring up the logs"    
    DIR=`dirname $NFSOUT`
    FNAME=`basename $NFSOUT`
    cd $DIR
    tar czvf $FNAME.tar.gz $FNAME >> /dev/null 2>&1
    sudo chown -R msevilla:msevilla $NFSOUT.tar.gz $NFSOUT
    cd -

    if [ "$CMD" == "teardown" ]; then
        echo -e "... cleanup working dir: $DIR"
        ceph-deploy forgetkeys
        rm ceph.conf ceph.log ceph-startup.log *.keyring *.conf *.log 
        
        echo "... stop MDSs"
        # This must be done manually, since we need to feed in the MDS ID
        for mds in $MDSs; do
            echo -e "\tissdm-$i"
            ssh $mds "sudo stop ceph-mds id=issdm-$i;" >> /dev/null 2>&1
        done
        echo
        
        echo "... stop OSDs"
        $SCRIPTS/ssh-all.sh OSDs $CONFIG "$SCRIPTS/cleanup.sh osd" blocking >> /dev/null 2>&1
        echo
        
        echo ".. stop MONs"
        for mon in $MONs; do
            echo -e "\tissdm-$i"
            ssh $mon "sudo stop ceph-mon id=issdm-$i"
        done
        echo
        
        echo "... delete all run directories"
        DELETE="sudo stop ceph-all"
        DELETE="$DELETE; sudo rm -r $OUT/*"
        DELETE="$DELETE; sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*"
        DELETE="$DELETE; sudo rm -r --one-file-system /mnt/ssd1/msevilla/* /mnt/ssd2/msevilla/* /mnt/ssd3/msevilla/*"
        DELETE="$DELETE; sudo rm -r --one-file-system /mnt/vol1/msevilla/* /mnt/vol2/msevilla/* /mnt/vol3/msevilla/*"
        $SCRIPTS/ssh-all.sh ALL $CONFIG "$DELETE" blocking >> /dev/null 2>&1

        echo "... checking that everything died"
        CHECK="ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
    elif [ "$CMD" == "reset" ]; then
        echo "... reset the cluster (same configs)"
        echo "... PGs=$PGs"
        ceph mds set_max_mds 20; 
        ceph mds cluster_down; 
        for i in {0..20}; do
            ceph mds fail $i
        done
        ceph fs rm sevilla_fs --yes-i-really-mean-it; 
        ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it;
        ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it;
        ceph osd pool create cephfs_data $PGs; 
        ceph osd pool create cephfs_metadata $PGs; 
        ceph osd pool set cephfs_data size 1; 
        ceph osd pool set cephfs_metadata size 1; 
        ceph fs new sevilla_fs cephfs_metadata cephfs_data; 
        sudo ceph osd crush tunables legacy
        sudo ceph osd pool set rbd hashpspool false
        sudo ceph osd pool set cephfs_data hashpspool false
        sudo ceph osd pool set cephfs_metadata hashpspool false   
    fi
else
    echo -e "Unrecognized command: $CMD"
fi
echo  "DONE!"
