#!/bin/bash

# Add hostanmes here (ensure passwordless login)
MONs="issdm-3"
MDSs="issdm-15"
OSDs="issdm-0 issdm-7 issdm-11 issdm-21 issdm-34 issdm-40"
DEAD="issdm-46 issdm-36 issdm-25"
CLIENTs="issdm-0 issdm-7 issdm-11 issdm-21"

# Sample rate
INTERVAL=10

# Where the Ceph daemons live
SOCKET="/var/run/ceph/ceph-mds.issdm-*.asok"
OSDSOCKET="/var/run/ceph/ceph-osd*.asok"

# Log files (used collect.sh)
OUT="/mnt/vol2/msevilla/ceph-logs"
NFSOUT="/user/msevilla/papers/pdsw15/cluster/4client"
