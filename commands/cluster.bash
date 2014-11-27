# Build debian
cd code/ceph
./autogen; ./configure
make -j32
debuild -b -nc -j32 -rfakeroot -us -uc

# Run experiments locally
sudo ../../cleanup.sh; sudo OSD=3 MDS=3 MON=1 ./vstart.sh -l -n; sudo ./ceph -c ceph.conf mds tell 0 '--debug-ms 0'; sudo ./ceph -c ceph.conf mds tell 1 '--debug-ms 0'; sudo ./ceph -c ceph.conf mds tell 2 '--debug-ms 0'
(sudo ./ceph-fuse -c ceph.conf /mnt/cephfs -d) > /mnt/vol2/msevilla/ceph-logs/client/client0 2>&1 &

# Run experiments on the cluster
@MON: ceph-deploy/start.sh
@ each CLIENT:
  mkdir /mnt/vol2/msevilla/ceph-logs/client
  (sudo ceph-fuse /mnt/cephfs -d) > /mnt/vol2/msevilla/ceph-logs/client/client0 2>&1 &
  sudo chown -R msevilla:msevilla /mnt/cephfs

# Start daemon to collect stats (right after heartbeat)
@MON: 
  vim config.sh
  ./collect.sh
  # Monitor experiment while it runs
  tailplot -x 2 --field-format=2,date,HH:mm:ss --x-format=date,HH:mm:ss -s 3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,20,21,22,23,24,25,26,27,29,30,31 -f traverse_discover,traverse,dir_fetch,dir_commit,traverse_remote_ino,inodes_bottom,imported,imported_inodes,inodes_pin_tail,traverse_forward,inodes_top,traverse_dir_fetch,inodes_pinned,reply,traverse_hit,subtrees,caps,forward,exported,exported_inodes,dir_split,inodes_expired,traverse_lock,request,inodes_with_caps,q,inodes ceph/src/out/perf/mds-issdm-a.timing &

# Run benchmark
@ each CLIENT: 
  /user/msevilla/programs/mdtest/mdtest -F -C -z 1000 -n 100000 -d /mnt/cephfs/dir0
  # Wait x seconds and force migration
  sudo ceph --admin-daemon /var/run/ceph/ceph-mds.issdm-15.asok config set debug_mds 0
  sudo ceph mds tell 0 injectargs "--mds_force_migrate /dir0:2"
  sudo ceph tell mds.0 injectargs --debug-mds 0

# After experiment
@MON: 
  # Stop all the daemons and collect logs
  ./stop.sh /user/msevilla/results/dir0

# Delete file system data: stop MDS and delete fs
@MON:
  ceph mds set_max_mds 0
  ceph mds cluster_down  
  ceph mds fail {2,1,0}
  ceph fs rm sevilla_fs --yes-i-really-mean-it
  ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it
  ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it
  ceph osd pool create cephfs_data 512
  ceph osd pool create cephfs_metadata 512
  ceph fs create sevilla_fs cephfs_data cephfs_metadata

# Kill all daemons (wipes out the cluster)
./reset.sh

