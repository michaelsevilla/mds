#!/bin/bash
# Reset the same cluster
source config/cluster.sh

echo "PGs=$PGs"
./stop.sh; 
ceph mds set_max_mds 20; 
ceph mds cluster_down; 
ceph mds fail 0; 
ceph mds fail 1; 
ceph mds fail 2; 
ceph mds fail 3; 
ceph mds fail 4; 
ceph mds fail 5; 
ceph mds fail 6; 
ceph mds fail 7; 
ceph mds fail 8; 
ceph mds fail 9; 
ceph mds fail 10; 
ceph mds fail 11; 
ceph mds fail 12; 
ceph mds fail 13; 
ceph mds fail 14; 
ceph mds fail 15; 
ceph mds fail 16; 
ceph mds fail 17; 
ceph mds fail 18; 
ceph mds fail 19; 
ceph mds fail 20; 
ceph fs rm sevilla_fs --yes-i-really-mean-it; 
ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it;
ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it;
ceph osd pool create cephfs_data $PGs; 
ceph osd pool create cephfs_metadata $PGs; 
ceph osd pool set cephfs_data size 1; 
ceph osd pool set cephfs_metadata size 1; 
ceph fs new sevilla_fs cephfs_metadata cephfs_data; 
sudo ceph osd crush tunables legacy
sudo ceph osd pool set rbd hashpspool false
sudo ceph osd pool set cephfs_data hashpspool false
sudo ceph osd pool set cephfs_metadata hashpspool false
