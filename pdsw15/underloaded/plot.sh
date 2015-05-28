#!/bin/bash
WORKDIR=`pwd`
ROOTDIR=`dirname $WORKDIR`
SCRIPTS=`dirname $ROOTDIR`"/scripts"
TOOLS=`dirname $ROOTDIR`"/tools"
$TOOLS/lttng-latency.py -d auto-20150527-090022/ust/uid/1001/64-bit/ -o latencies.dat
$TOOLS/tailplot/tailplot latencies.dat -x 1 --field-format=1,date,HH:mm:ss --x-format=date,HH:mm:ss -s 2,3,4 -f numrequests,latency,avg --y2=2 &
