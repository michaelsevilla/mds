#!/bin/bash

if [ $# -lt 1 ]; then
    echo -e "USAGE: $0 [osd|client]"
    exit
fi
DAEMON=$1

if [ "$DAEMON" == "client" ]; then
    pid=`ps ax | grep ceph-fuse | grep -v grep | awk '{print $1}'`
    mnt="/mnt/cephfs"

    kill -9 $pid
    umount $mnt
elif [ "$DAEMON" == "osd" ]; then
    osds=`ps ax | grep ceph-osd | grep -v grep | awk '{print $8}'`
    for o in $osds; do sudo stop ceph-osd id=$o; done
fi

