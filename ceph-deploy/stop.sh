#!/bin/bash
source config/cluster.sh

if [ $# -lt 2 ]; then
    echo -e "USAGE: $0 <output dir> [reset|stop|teardown]"
    echo -e "Options:"
    echo -e "\t output dir: where to put the ceph logs"
    echo -e "\t reset: delete the data"
    echo -e "\t stop: stop collectl, unmount clients, copy logs"
    echo -e "\t teardown: stop all Ceph daemons and delete data"
    exit
fi

NFSOUT=$1
echo "Writing to $NFSOUT"
CMD=$2
echo "Command: $CMD"
WORKINGDIR=`pwd`
echo "Working directory: $WORKINGDIR"
SCRIPTS="`dirname $WORKINGDIR`/scripts"
echo "Scripts directory: $SCRIPTS"

mkdir -p $NFSOUT/dump-daemons $NFSOUT/osd/perf $NFSOUT/osd/cpu $NFSOUT/mds/perf $NFSOUT/mds/cpu $NFSOUT/mon $NFSOUT/config $NFSOUT/client > /dev/null 2>&1

if [ "$cmd" == teardown ]; then
    echo -n "I'm about to tear down the Ceph cluster, are you sure [y/n]? "
    read teardown
    if [ "$teardown" == "n" ]; then
        exit
    fi
fi

if [ "$CMD" == "teardown" ] || [ "$CMD" == "stop" ] || [ "$CMD" == "reset" ]; then
    echo "umounting..."
    for CLIENT in $CLIENTs; do
        echo -e "\t issdm-$CLIENT"
        ssh issdm-$CLIENT " sudo umount /mnt/cephfs > /dev/null 2>&1; \
                            sudo pkill ceph-fuse; \
                            $WORKINGDIR/cleanup.sh client" >> /dev/null 2>&1
    done
    
    echo "copying logs..."
    for i in $MONs; do
        echo "issdm-$i (MON)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/; \
                        sudo cp /etc/ceph/ceph.conf $NFSOUT/config/ceph.conf; " >> /dev/null 2>&1
    done
    for i in $MDSs; do
        echo "issdm-$i (MDS)" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    for i in $OSDs; do
        echo "issdm-$i (OSD)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    for i in $CLIENTs; do
        echo "issdm-$i" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null 2>&1
    done
    
    # copy some last things over
    DIR=`pwd`
    echo -e "Cleanup working dir: $DIR"
    ls $DIR
    rm ceph.conf  ceph.log  ceph-startup.log *.keyring *.conf *.log 
    DIR=`dirname $NFSOUT`
    cd $DIR
    FNAME=`basename $NFSOUT`
    tar czvf $FNAME.tar.gz $FNAME >> /dev/null 2>&1
    sudo chown -R msevilla:msevilla $NFSOUT.tar.gz $NFSOUT
    cd -
    
    echo "killing collectl, deleting logs..."
    for i in $ALL; do
        echo -e "\t issdm-$i"
        ssh issdm-$i " sudo pkill collectl; \
                       ps ax | grep dump | grep -v greph | awk '{print \$1}' | while read p; do sudo kill -9 \$p; done; \
                       rm -r $OUT/* > /dev/null 2>&1; \
                       ls $OUT;" >> /dev/null 2>&1
    done
    
    if [ "$CMD" == "teardown" ]; then
        ceph-deploy forgetkeys;
        
        echo "Stopping MDSs..."
        for i in $MDSs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-mds id=issdm-$i;"
        done
        echo
        
        echo "Stopping OSDs..."
        for i in $OSDs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  /user/msevilla/ceph-deploy/job-scripts/cleanup-osd.sh;"
        done
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
                            sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*; \
                            sudo rm -r --one-file-system /mnt/ssd1/msevilla/* /mnt/ssd2/msevilla/* /mnt/ssd3/msevilla/*; \
                            sudo rm -r --one-file-system /mnt/vol1/msevilla/* /mnt/vol2/msevilla/* /mnt/vol3/msevilla/*;" >> /dev/null 2>&1
            ssh issdm-$i "  ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
        done 
        echo
    fi
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
else
    echo -e "Unrecognized command: $CMD"
fi

