#!/bin/bash

# Nodes
MONs="3"
#OSDs="0 21 34 39 40 46"
OSDs="0 21 34 40 46"
MDSs="15 41 5"
CLIENTs="11 44 39"
#CLIENTs=""
ALL="3 0 21 34 39 40 15 41 5 11 44 46 36"

# Install
DEB="/user/msevilla/ceph-lua_3_amd64.deb"
UNSTABLE=0
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
