# Build debian
cd code/ceph; ./autogen; ./configure; make -j32
debuild -b -nc -j32 -rfakeroot -us -uc

# Run experiments locally
sudo ../../cleanup.sh; sudo OSD=3 MDS=3 MON=1 ./vstart.sh -l -n; sudo ./ceph -c ceph.conf mds tell 0 '--debug-ms 0'; sudo ./ceph -c ceph.conf mds tell 1 '--debug-ms 0'; sudo ./ceph -c ceph.conf mds tell 2 '--debug-ms 0'
(sudo ./ceph-fuse -c ceph.conf /mnt/cephfs -d) > /mnt/vol2/msevilla/ceph-logs/client/client0 2>&1 &

# Bring up the cluster
check MDS config and config.sh
sudo mount /dev/sdb1 /mnt/vol1 -o noexec -o noexec -o nodev -o noatime -o nodiratime -o nobarrier
@MON: ceph-deploy/start.sh

# Run experiments on the cluster
@ each CLIENT:
  export CLIENT=
  (sudo ceph-fuse /mnt/cephfs -d) > /mnt/vol2/msevilla/ceph-logs/client/client$CLIENT 2>&1 &
  sudo chown -R msevilla:msevilla /mnt/cephfs
  /user/msevilla/programs/mdtest/mdtest -F -C -n 100000 -d /mnt/cephfs/dir-$CLIENT > /mnt/vol2/msevilla/ceph-logs/client/job$CLIENT 2>&1 &
  tail -f /mnt/vol2/msevilla/ceph-logs/client/job$CLIENT  
@MON: 
  ./collect.sh

# After experiment
@MON: 
  # Stop all the daemons and collect logs
  ./stop.sh /user/msevilla/results/dir0

# Delete file system data: stop MDS and delete fs
@MON:
  ./stop.sh; ceph mds set_max_mds 0; ceph mds cluster_down; ceph mds fail 0; ceph fs rm sevilla_fs --yes-i-really-mean-it; ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it;   ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it; ceph osd pool create cephfs_data $PGs; ceph osd pool create cephfs_metadata $PGs; ceph osd pool set cephfs_data size 1; ceph osd pool set cephfs_metadata size 1; ceph fs new sevilla_fs cephfs_metadata cephfs_data; 
  ./stop.sh; ceph mds set_max_mds 0; ceph mds cluster_down; ceph mds fail 0; ceph mds fail 1; ceph mds fail 2; ceph fs rm sevilla_fs --yes-i-really-mean-it; ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it;   ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it; ceph osd pool create cephfs_data $PGs; ceph osd pool create cephfs_metadata $PGs; ceph osd pool set cephfs_data size 1; ceph osd pool set cephfs_metadata size 1; ceph fs new sevilla_fs cephfs_metadata cephfs_data; 

# Kill all daemons (wipes out the cluster)
./reset.sh

# Insert Ceph Where balancer
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.issdm-15.asok config set mds_bal_where "\\ne=1;i=1;eLoad=1;iLoad=1\\ntarget=total/#MDSs\\nfor_i=0,#MDSs\\n__if_MDSs[i][\"load\"]<target_then_table.insert(importers,{i,MDSs[i][\"load\"})\\n__else_table.insert(exporters,{i,MDSs[i][\"load\"]}_end\\ntable.sort(exporters,function(a,b)_return_a[2]>b[2]_end)\\ntable.sort(importers,function(a,b)_return_a[2]>b[2]_end)\\nwhile_(e<=#exporters_and_i<=#importers)_and_(eLoad<.001_and_iLoad>.001)_do\\n__niLoad=target-importers[i][2]\\n__eLoad=exporters[e][2]-target\\n__amount=math.min(eLoad,iLoad)\\n__if_e==whoami_then_targets[i]=targets[i]+amount_end\\n__exporters[e][2]=exporters[e][2]-amount\n__importers[i][2]=importers[i][2]+amount\\n__if_eLoad<=.001_then_e=e+1_end\\n__if_iLoad<=.001_then_i=i+1_end\\nend"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.issdm-15.asok config set mds_bal_where "\\ne=1;i=1;eLoad=1;iLoad=1\\ntarget=total/#MDSs\\nfor_i=0,#MDSs_do\\n__if_MDSs[i][\"load\"]<target_then_table.insert(importers,{i,MDSs[i][\"load\"]})\\n__else_table.insert(exporters,{i,MDSs[i][\"load\"]})_end\\ntable.sort(exporters,function(a,b)_return_a[2]>b[2]_end)\\ntable.sort(importers,function(a,b)_return_a[2]>b[2]_end)\\nwhile_(e<=#exporters_and_i<=#importers)_and_(eLoad<.001_and_iLoad>.001)_do\\n__niLoad=target-importers[i][2]\\n__eLoad=exporters[e][2]-target\\n__amount=math.min(eLoad,iLoad)\\n__if_e==whoami_then_targets[i]=targets[i]+amount_end\\n__exporters[e][2]=exporters[e][2]-amount\n__importers[i][2]=importers[i][2]+amount\\n__if_eLoad<=.001_then_e=e+1_end\\n__if_iLoad<=.001_then_i=i+1_end\\nend"
