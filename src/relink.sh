#!/bin/bash

FILES=`find ./ -name "*.cc" -or -name "*.h"`
for f in $FILES
do
    echo -e "\t relinking $f"
    unlink $f
    link /home/msevilla/code/ceph/src/$f $f
done
