#!/bin/bash
# Start the cluster
WORKINGDIR=`pwd`
source $WORKINGDIR/config/cluster.sh


if [ "$#" -lt 2 ]; then
    echo "Usage: <who> (<command>|mount|cleanup-client)"
    exit
fi

who="$1" 
what="$2"
append=1
if [ -z $3 ]; then
    append=0
fi

if [ "$who" == "MDSs" ]; then
    d=$MDSs
elif [ "$who" == "ALL" ]; then
    d=$ALL
elif [ "$who" == "OSDs" ]; then
    d=$OSDs
elif [ "$who" == "CLIENTs" ]; then
    d=$CLIENTs
else
    echo "Whoops, choose a \"who\" from ALL, OSDs, MDSs, or CLIENTs"
    exit
fi

echo "sending command to $d"
echo "command: $what"
if [ $append -eq 1 ]; then
    echo "appending iteration number"
fi

if [ "$what" == "mount" ]; then
    what="ceph-deploy/job-scripts/mount-client.sh"
    append=1
elif [ "$what" == "cleanup-client" ]; then
    what="ceph-deploy/job-scripts/cleanup-client.sh"
    append=1
fi

for i in $d; do
    echo
    echo "----- issdm-$i -----"
    if [ $append -eq 1 ]; then
        ssh issdm-$i "$what $i"
    else
        ssh issdm-$i $what
    fi
done
