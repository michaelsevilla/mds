#!/bin/bash

# Nodes
ALL="0 3 5 7 10 11 15 21 34 39 40 41"
MONs="3"
MDSs="15"
OSDs="0 7 11 21 34 40"
DEAD="46 36 25"
CLIENTs="0 7 11 21 34"
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
SCRIPTS="/user/msevilla/mds/ceph-deploy/"
NFS="/user/msevilla/ceph-logs/"
INTERVAL=10
