#!/bin/bash
# Kill collect.sh processes
source config.sh

if [ $# -lt 1 ]; then
    echo -e "**********\nYou didn't give me a directory to spit to\n***********\n"
else
    NFSOUT=$1
    echo "Writing to $NFSOUT"
fi

echo "pkill collectl..."
for MDS in $MDSs; do
    echo -e "\t issdm-$MDS"
    ssh issdm-$MDS "    sudo pkill collectl;"
done
for OSD in $OSDs; do
    echo -e "\t issdm-$OSD"
    ssh issdm-$OSD "    sudo pkill collectl;"
done

echo "umounting..."
for CLIENT in $CLIENTs; do
    echo -e "\t issdm-$CLIENT"
    ssh issdm-$CLIENT " sudo umount /mnt/cephfs > /dev/null 2>&1; \
                        sudo pkill collectl;"
done

if [ $# -ge 1 ]; then
    echo "copying logs..."
    for i in $MDSs; do
        echo "issdm-$i (MDS)" 
        ssh issdm-$i "  cp -r $OUT/* $NFSOUT/"
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

