#!/bin/bash
# Kill collect.sh processes
source config/cluster.sh

if [ $# -lt 1 ]; then
    echo -e "**********\nYou didn't give me a directory to spit to\n***********\n"
else
    NFSOUT=$1
    mkdir $NFSOUT > /dev/null 2>&1
    echo "Writing to $NFSOUT"
fi

umount="y"
logs="y"

if [ "$umount" == "y" ]; then
    echo "umounting..."
    for CLIENT in $CLIENTs; do
        echo -e "\t issdm-$CLIENT"
        ssh issdm-$CLIENT " sudo umount /mnt/cephfs > /dev/null 2>&1; \
                            sudo pkill ceph-fuse; \
                            ceph-deploy/job-scripts/cleanup-client.sh 1" >> /dev/null
    done
fi

if [ $# -ge 1 ]; then
    echo "copying logs..."
    for i in $MONs; do
        echo "issdm-$i (MON)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/; \
                        sudo cp -r ceph-deploy/job-scripts/ $NFSOUT/job-scripts; \
                        sudo cp -r ceph-deploy/config* $NFSOUT/status/" >> /dev/null
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
    cd $NFSOUT/perf/
    /user/msevilla/ceph-deploy/parse_reply_thruput.sh
    cd -
    sudo chown -R msevilla:msevilla $OUT/*
fi

if [ "$logs" == "y" ]; then
    echo "killing collectl, deleting logs..."
    for i in $ALL; do
        echo -e "\t issdm-$i"
        ssh issdm-$i " sudo pkill collectl; \
                       rm -r $OUT/perf $OUT/cpu $OUT/status $OUT/client > /dev/null 2>&1; \
                       ls $OUT;" >> /dev/null
    done
fi
