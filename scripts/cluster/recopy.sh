#!/bin/bash

FILES="start.sh stop.sh reset.sh config.sh collect.sh ceph.template"
for f in $FILES
do
    echo -e "\t relinking $f"
    cp /user/msevilla/ceph-deploy/$f $f
done
