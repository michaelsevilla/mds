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

mkdir $NFSOUT > /dev/null 2>&1

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
                            $WORKINGDIR/cleanup.sh client" >> /dev/null
    done
    
    echo "copying logs..."
    for i in $MONs; do
        echo "issdm-$i (MON)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/; \
                        sudo cp -r $WORKINGDIR/job-scripts/ $NFSOUT/job-scripts; \
                        sudo cp -r $WORKINGDIR/config* $NFSOUT/status/" >> /dev/null
    done
    for i in $MDSs; do
        echo "issdm-$i (MDS)" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null
    done
    for i in $OSDs; do
        echo "issdm-$i (OSD)"
        ssh issdm-$i "  cp -r $OUT/osd/* $NFSOUT/osd/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/" >> /dev/null
    done
    mkdir $NFSOUT/client $NFSOUT/cpu
    for i in $CLIENTs; do
        echo "issdm-$i" 
        ssh issdm-$i "  cp -r $OUT/client/* $NFSOUT/client/; \
                        cp -r $OUT/cpu/* $NFSOUT/cpu/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/; \
                        sudo rm -r /mnt/vol2/msevilla/ceph-logs/client/*" >> /dev/null
    done
    
    # copy some last things over
    cp -r $OUT/mon/* $NFSOUT/mon/
    tar czvf $NFSOUT.tar.gz $NFSOUT
    sudo chown -R msevilla:msevilla $OUT/*
    
    echo "killing collectl, deleting logs..."
    for i in $ALL; do
        echo -e "\t issdm-$i"
        ssh issdm-$i " sudo pkill collectl; \
                       rm -r $OUT/perf $OUT/cpu $OUT/status $OUT/client > /dev/null 2>&1; \
                       ls $OUT;" >> /dev/null
    done
    
    if [ "$CMD" == "teardown" ]; then
        if [ $UNINSTALL -eq 1 ]; then 
            echo "Uninstalling on all nodes: $ALL"
            for i in $ALL
            do
                ceph-deploy purge issdm-$i;
                ceph-deploy purgedata issdm-$i;
                ceph-deploy purge issdm-$i;
                ceph-deploy purgedata issdm-$i;
                sudo dpkg --remove ceph-lua; 
                sudo dpkg --purge librbd1;
                sudo apt-get remove -y librbd1 ceph-fuse; 
            done
            echo
        fi
        
        ceph-deploy forgetkeys;
        
        echo "Stopping MDSs..."
        for i in $MDSs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-mds id=issdm-$i; \
                            sudo opcontrol --deinit;" > $LOG 2>&1
        done
        echo
        
        echo "Stopping OSDs..."
        for i in $OSDs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  /user/msevilla/ceph-deploy/job-scripts/cleanup-osd.sh; \
                            " >> $LOG 2>&1
        done
        echo
        
        echo "Stopping MONs..."
        for i in $MONs; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-mon id=issdm-$i" >> $LOG 2>&1
        done
        echo
        
        echo "Checking for straggler processes..."
        for i in $ALL; do
            echo -e "\tissdm-$i"
            ssh issdm-$i "  sudo stop ceph-all; \
                            sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*; \
                            sudo rm -r --one-file-system /mnt/ssd1/msevilla/* /mnt/ssd2/msevilla/* /mnt/ssd3/msevilla/*; \
                            sudo rm -r --one-file-system /mnt/vol1/msevilla/* /mnt/vol2/msevilla/* /mnt/vol3/msevilla/*;" >> $LOG 2>&1
            ssh issdm-$i "  ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
        done 
        echo
        echo -e "Cleanup working dir"
        rm ceph.conf  ceph.log  ceph-startup.log
    fi
elif [ "$CMD" == "reset" ]; then
    echo "Resetting the cluster (same configs)"
    echo "PGs=$PGs"
    ceph mds set_max_mds 20; 
    ceph mds cluster_down; 
    ceph mds fail 0; 
    ceph mds fail 1; 
    ceph mds fail 2; 
    ceph mds fail 3; 
    ceph mds fail 4; 
    ceph mds fail 5; 
    ceph mds fail 6; 
    ceph mds fail 7; 
    ceph mds fail 8; 
    ceph mds fail 9; 
    ceph mds fail 10; 
    ceph mds fail 11; 
    ceph mds fail 12; 
    ceph mds fail 13; 
    ceph mds fail 14; 
    ceph mds fail 15; 
    ceph mds fail 16; 
    ceph mds fail 17; 
    ceph mds fail 18; 
    ceph mds fail 19; 
    ceph mds fail 20; 
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

