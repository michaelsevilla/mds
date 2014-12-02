#!/bin/bash
# Kill collect.sh processes
source config.sh

if [ $# -lt 1 ]; then
    echo -e "**********\nYou didn't give me a directory to spit to\n***********\n"
else
    NFSOUT=$1
    echo "Writing to $NFSOUT"
fi

echo "unmount clients [y/n]?"
read ans
if [ "$ans" == "y" ]; then
    echo "umounting..."
    for CLIENT in $CLIENTs; do
        echo -e "\t issdm-$CLIENT"
        ssh issdm-$CLIENT " sudo umount /mnt/cephfs > /dev/null 2>&1; \
                            sudo pkill ceph-fuse;"
    done
fi

if [ $# -ge 1 ]; then
    echo "copying logs..."
    for i in $MONs; do
        echo "issdm-$i (MON)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/; \
                        sudo cp -r /var/log/ceph/ $NFSOUT/varlogceph/"
    done
    for i in $MDSs; do
        echo "issdm-$i (MDS)" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/;"
    done
    for i in $OSDs; do
        echo "issdm-$i (OSD)"
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/"
    done
    for i in $CLIENTs; do
        echo "issdm-$i" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/"
    done
    echo "ls $NFSOUT"
    cp -r $OUT/* $NFSOUT/
    ls $NFSOUT
fi

echo "delete logs [y/n]?"
read ans
if [ "$ans" == "y" ]; then
    echo "killing collectl, deleting logs..."
    for i in $ALL; do
        echo -e "\t issdm-$i"
        ssh issdm-$i " sudo pkill collectl; \
                       rm -r $OUT/perf $OUT/cpu $OUT/status > /dev/null 2>&1; \
                       ls $OUT;"
    done
fi
