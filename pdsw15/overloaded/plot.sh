#!/bin/bash
WORKDIR=`pwd`
ROOTDIR=`dirname $WORKDIR`
SCRIPTS=`dirname $ROOTDIR`"/scripts"
TOOLS=`dirname $ROOTDIR`"/tools"
DIR=`ls ./ | grep auto`
$TOOLS/lttng-latency.py \
    -d $DIR/ust/uid/1001/64-bit/ \
    -o latencies.dat \
    -t CEPH_MDS_OP_LOOKUP
$TOOLS/tailplot/tailplot latencies.dat \
    -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss \
    -s 2,3,4 \
    -f numrequests,latency,avg \
    --y2=2 &

