#!/bin/bash

# Nodes
#ALL="0 3 5 7 10 11 15 21 34 39 40 41"
#ALL="0 1 2 3 4 5 7 8 9 10 11 13 14 15 16 17 18 21 23 24 29 34 39 40 41 46 47"
ALL="0 1 3 4 5 7 8 10 11 13 14 15 16 17 18 21 23 24 34 39 40 41 47"
MONs="3"
#MDSs="15 41 5 10 39"
MDSs="15 41 5 10 39 1 4 8 13 14 16 17 18 23 24 47"
OSDs="0 7 11 21 34 40"
DEAD="46 36 25"
#CLIENTs="0 7 11 21 34"
CLIENTs="15 41 5 10 39 1 4 8 13 14 16 17 18 23 24 47"
COLOCATED_CLIENTS=1
DEAD=""

# Install
UNSTABLE=1
INSTALL=0
UNINSTALL=0

# Log files (used collect.sh)
OUT="/mnt/vol2/msevilla/ceph-logs"
SOCKET="/var/run/ceph/ceph-mds.issdm-*.asok"
OSDSOCKET="/var/run/ceph/ceph-osd*.asok"
SCRIPTS="/user/msevilla/ceph-deploy/scripts"
NFS="/user/msevilla/ceph-logs/"
INTERVAL=10
LOG="./ceph-startup.log"
