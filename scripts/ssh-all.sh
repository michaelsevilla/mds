#!/bin/bash


if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <who> (<command>|mount|cleanup-client) <config file>"
    exit
fi
echo "config=$3"
source $3

who="$1" 
what="$2"

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
    echo "Whoops, choose a \"who\" from ALL, OSDs, MDSs, or CLIENTs"
    exit
fi

echo "sending command to $d"
echo "command: $what"

for i in $d; do
    echo
    echo "----- issdm-$i -----"
    ssh -f issdm-$i $what
done
