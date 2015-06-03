#!/bin/bash


if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <who> <config> <command> (blocking)"
    exit
fi
source $2

who="$1" 
what="$3"
blocking=0
if [ "$#" -gt 3 ]; then 
    if [ "$4" == "blocking" ]; then
        echo "Using blocking ssh..."
        blocking=1
    else
        echo "The last argument can only be \"blocking\""
        exit
    fi
fi

if [ "$who" == "MDSs" ]; then
    d=$MDSs
elif [ "$who" == "MONs" ]; then
    d=$MONs
elif [ "$who" == "ALL" ]; then
    d=$ALL
elif [ "$who" == "OSDs" ]; then
    d=$OSDs
elif [ "$who" == "CLIENTs" ]; then
    d=$CLIENTs
else
    echo "Whoops, choose a \"who\" from ALL, OSDs, MDSs, MONs, or CLIENTs"
    exit
fi

echo
echo "==================="
echo "sending command to $d"
echo "command: $what"
echo "==================="
sleep 1
for i in $d; do
    echo
    echo "----- issdm-$i -----"
    if [ $blocking -eq 0 ]; then
        ssh -f issdm-$i $what
    else
        ssh issdm-$i $what
    fi
    sleep 1
done
