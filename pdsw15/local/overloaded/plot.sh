#!/bin/bash
WORKDIR=`pwd`
ROOTDIR=`dirname $WORKDIR`
SCRIPTS=`dirname $ROOTDIR`"/scripts"
TOOLS=`dirname $ROOTDIR`"/tools"
DIR=`ls ./ | grep auto`
$TOOLS/lttng-latency.py \
    -d $DIR/ust/uid/1001/64-bit/ \
    -o creates.dat \
    -t CEPH_MDS_OP_CREATE
$TOOLS/lttng-latency.py \
    -d $DIR/ust/uid/1001/64-bit/ \
    -o lookups.dat \
    -t CEPH_MDS_OP_LOOKUP
$TOOLS/tailplot/tailplot \
    creates.dat \
    -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss \
    -s 2,3 \
    -f nCreates,latCreates \
    --y2=2 \
    lookups.dat \
    -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss \
    -s 2,3 \
    -f nLookups,latLookups \
    --y2=2 &

