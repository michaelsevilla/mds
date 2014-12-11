#!/bin/bash
# Start the cluster
source config.sh
set -e

if [ $INSTALL -eq 1 ]; then 
    for i in $ALL; do
        ssh issdm-$i "  sudo dpkg -i $DEB"
    done
fi

#ceph-deploy install issdm-{0,3,5,10,13,14,15,16,17,34};
echo "Starting MONs on $MONs"
ceph-deploy new issdm-$MONs;
ssh issdm-$MONs "   sudo mkdir -p /mnt/vol2/msevilla/ceph-logs/mon /var/log/ceph; "
cat ./ceph.template >> ceph.conf;
ceph-deploy mon create-initial;
echo

echo "Setting nodes to admin on $ALL"
for i in $ALL; do
    ssh issdm-$i "  sudo mkdir -p /etc/ceph /var/log/ceph; \
                    sudo chown -R msevilla:msevilla /etc/ceph /var/log/ceph;"
    ceph-deploy admin issdm-$i
done
echo
echo "Starting OSDs on $OSDs"
for i in $OSDs; do
    ssh issdm-$i "  sudo mkdir -p /var/lib/ceph/osd/ /var/lib/ceph/tmp/ /var/lib/ceph/bootstrap-osd $OUT/osd /etc/ceph /mnt/vol1/msevilla/ceph-data /mnt/vol2/msevilla/ceph-logs; \
                    sudo chown -R msevilla:msevilla /var/lib/ceph/ $OUT/osd /mnt/vol1/msevilla/ /mnt/vol2/msevilla/ /etc/ceph;"
                    #sudo opcontrol --deinit > /dev/null 2>&1; \
                    #sudo opcontrol --init; \
                    #sudo opcontrol --setup --vmlinux=/users/msevilla/vmlinux --separate=library; \
                    #sudo opcontrol --event=default; \
                    #sudo opcontrol --start;"
    ceph-deploy osd prepare issdm-$i:/mnt/vol1/msevilla/ceph-data:/mnt/vol3/msevilla/ceph-data/journal;
    ceph-deploy osd activate issdm-$i:/mnt/vol1/msevilla/ceph-data:/mnt/vol3/msevilla/ceph-data/journal;
done
echo

if [ $UNSTABLE -eq 1 ]; then
    echo "Setting tunables"
    sudo ceph osd crush tunables legacy
    sudo ceph osd crush rule rm erasure_ruleset
    sudo ceph osd pool set rbd hashpspool false
    sudo ceph osd pool set metadata hashpspool false
    sudo ceph osd pool set data hashpspool false
    echo
fi

echo "Starting MDSs on $MDSs"
ceph osd pool create cephfs_data $PGs
ceph osd pool create cephfs_metadata $PGs
ceph osd pool set cephfs_data size 1
ceph osd pool set cephfs_metadata size 1
ceph fs new sevilla_fs cephfs_metadata cephfs_data
for i in $MDSs; do
    ssh issdm-$i "  sudo mkdir -p /var/lib/ceph/bootstrap-mds /var/lib/ceph/mds $OUT/mds;"
                    #sudo opcontrol --deinit; \
                    #sudo opcontrol --init; \
                    #sudo opcontrol --setup --vmlinux=/users/msevilla/vmlinux --separate=library; \
                    #sudo opcontrol --event=default; \
                    #sudo opcontrol --start;"
    ceph-deploy mds create issdm-$i
    sleep 1
done
echo

echo "Going to sleep while the cluster initializes..."
sleep 60
echo "Checking status..."
sudo ceph -s

sudo chown msevilla:msevilla -R /mnt/vol2/msevilla
rm -r $OUT/
mkdir -p $OUT/status
sudo ceph -s > $OUT/status/status
sudo cp /etc/ceph/ceph.conf $OUT/status/

echo "Starting the clients"
j=0
for i in $CLIENTs; do
    echo -e "\t issdm-$i"
    ssh issdm-$i "  mkdir -p $OUT/client; \
                    (sudo ceph-fuse /mnt/cephfs -d) > $OUT/client/client$j 2>&1 &"
    ssh issdm-$i "  sudo chown -R msevilla:msevilla /mnt/cephfs;"
    j=$(($j+1))
done
echo "Fin."
