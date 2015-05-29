#!/bin/bash

if [ $# -lt 1 ]; then
    echo -e "USAGE: $0 [osd|client]"
    exit
fi
DAEMON=$1

if [ "$DAEMON" == "client" ]; then
    echo "Cleaning up CLIENTs..."
    pid=`ps ax | grep ceph-fuse | grep -v grep | awk '{print $1}'`
    mnt="/mnt/cephfs"

    echo "killing pid=$pid"
    kill -9 $pid
    echo "unmounting $mnt"
    umount $mnt
elif [ "$DAEMON" == "osd" ]; then
    echo "Cleaning up OSDs..."
    osds=`ps ax | grep ceph-osd | grep -v grep | awk '{print $8}'`
    for o in $osds; do sudo stop ceph-osd id=$o; done
    #for p in $pids; do sudo kill -9 $p; done
    #rm -r /mnt/cephfs/* > /dev/null 2>&1
fi

