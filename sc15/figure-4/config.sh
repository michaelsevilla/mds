#!/bin/bash

# Nodes
ALL="0 3 5 10 11 15 21 34 39 40 41 46"
MONs="3"
MDSs="15 41 46"
OSDs="0 11 21 34 39 40"
CLIENTs="0 11 21"
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
