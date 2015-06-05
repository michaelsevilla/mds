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
    echo "umounting..."
    UMOUNT="sudo umount /mnt/cephfs > /dev/null 2>&1"
    UMOUNT="$UMOUNT; sudo pkill ceph-fuse"
    UMOUNT="$UMOUNT; $SCRIPTS/cleanup.sh client"
    $SCRIPTS/ssh-all.sh CLIENTs $CONFIG "$UMOUNT" blocking
    
    echo "copying logs..."
    for i in $MONs; do
        echo -e "\t issdm-$i (MON)"
        ssh issdm-$i "  sudo chown -R msevilla:msevilla $OUT; \
                        cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/; \
                        sudo cp /etc/ceph/ceph.conf $NFSOUT/config/ceph.conf; " >> /dev/null 2>&1
    done
    for i in $MDSs; do
        echo -e "\t issdm-$i (MDS)" 
        ssh issdm-$i "  sudo chown -R msevilla:msevilla $OUT; \
                        cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    for i in $OSDs; do
        echo -e "\t issdm-$i (OSD)"
        ssh issdm-$i "  sudo chown -R msevilla:msevilla $OUT; \
                        cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    for i in $CLIENTs; do
        echo -e "\t issdm-$i" 
        ssh issdm-$i "  sudo chown -R msevilla:msevilla $OUT; \
                        cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    
   
    echo "killing collectl, deleting logs..."
    for i in $ALL; do
        echo -e "\t issdm-$i"
        ssh issdm-$i " sudo pkill collectl; \
                       ps ax | grep dump | grep -v greph | awk '{print \$1}' | while read p; do sudo kill -9 \$p; done; \
                       rm -r $OUT/* > /dev/null 2>&1; \
                       ls $OUT;" >> /dev/null 2>&1
    done

    echo "tarring up the logs"    
    DIR=`dirname $NFSOUT`
    FNAME=`basename $NFSOUT`
    cd $DIR
    tar czvf $FNAME.tar.gz $FNAME >> /dev/null 2>&1
    sudo chown -R msevilla:msevilla $NFSOUT.tar.gz $NFSOUT
    cd -
    if [ "$CMD" == "teardown" ]; then
        echo -e "Cleanup working dir: $DIR"
        ceph-deploy forgetkeys
        rm ceph.conf  ceph.log  ceph-startup.log *.keyring *.conf *.log 
        
        echo "Stopping MDSs..."
        for i in $MDSs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-mds id=issdm-$i;"
        done
        echo
        
        echo "Stopping OSDs..."
        $SCRIPTS/ssh-all.sh OSDs $CONFIG "$SCRIPTS/cleanup.sh osd" blocking
        echo
        
        echo "Stopping MONs..."
        for i in $MONs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-mon id=issdm-$i"
        done
        echo
        
        echo "Checking for straggler processes..."
        for i in $ALL; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-all; \
                            sudo rm -r $OUT/*; \
                            sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*; \
                            sudo rm -r --one-file-system /mnt/ssd1/msevilla/* /mnt/ssd2/msevilla/* /mnt/ssd3/msevilla/*; \
                            sudo rm -r --one-file-system /mnt/vol1/msevilla/* /mnt/vol2/msevilla/* /mnt/vol3/msevilla/*;" >> /dev/null 2>&1
            ssh issdm-$i "  ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
        done 
        echo
    elif [ "$CMD" == "reset" ]; then
        echo "Resetting the cluster (same configs)"
        echo "PGs=$PGs"
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

