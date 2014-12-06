#!/bin/bash

#FILES=`find ./ -name "*.sh"`
FILES="start.sh stop.sh reset.sh config.sh collect.sh"
for f in $FILES
do
    echo -e "\t relinking $f"
    #unlink $f
    cp /user/msevilla/ceph-deploy/$f $f
done
