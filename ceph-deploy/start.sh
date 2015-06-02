#!/bin/bash
# Start the cluster
source config/cluster.sh
set -e

LOG="./ceph-startup.log"

echo "Starting MONs on $MONs"
ceph-deploy new issdm-$MONs;
ssh issdm-$MONs "   sudo mkdir -p /mnt/vol2/msevilla/ceph-logs/mon /var/log/ceph /mnt/vol2/msevilla/ceph-logs/client /etc/ceph;"
cat ./config/default.sh >> ceph.conf;
ceph-deploy mon create-initial;
echo

echo "Setting nodes to admin on $ALL"
for i in $ALL; do
    echo "- setting up issdm-$i" >> $LOG 
    ssh issdm-$i "  sudo mkdir -p /etc/ceph /var/log/ceph; \
                    sudo chown -R msevilla:msevilla /etc/ceph /var/log/ceph; \
                    sudo chown -R msevilla:msevilla /mnt/vol1/msevilla /mnt/vol2/msevilla /mnt/vol3/msevilla; \
                    mkdir -p /mnt/vol1/msevilla/ceph-data /mnt/vol1/msevilla/ceph-logs; \
                    mkdir -p /mnt/vol2/msevilla/ceph-data /mnt/vol2/msevilla/ceph-logs; \
                    mkdir -p /mnt/vol3/msevilla/ceph-data /mnt/vol3/msevilla/ceph-logs;" >> $LOG 2>&1
   ceph-deploy admin issdm-$i
done
echo


echo "Starting OSDs on $OSDs"
for i in $OSDs; do
    ssh issdm-$i "  sudo mkdir -p /var/lib/ceph/osd/ /var/lib/ceph/tmp/ /var/lib/ceph/bootstrap-osd; \
                    sudo chown -R msevilla:msevilla /var/lib/ceph/; \
                    sudo mkdir -p /mnt/ssd1/msevilla/ceph-data /mnt/ssd2/msevilla/ceph-data /mnt/ssd3/msevilla/ceph-data; \
                    sudo chown -R msevilla:msevilla /mnt/ssd1/msevilla /mnt/ssd2/msevilla /mnt/ssd3/msevilla;"
    ceph-deploy osd prepare issdm-$i:/mnt/vol1/msevilla/ceph-data:/mnt/ssd1/msevilla/ceph-data/journal;
    ceph-deploy osd prepare issdm-$i:/mnt/vol2/msevilla/ceph-data:/mnt/ssd2/msevilla/ceph-data/journal;
    ceph-deploy osd prepare issdm-$i:/mnt/vol3/msevilla/ceph-data:/mnt/ssd3/msevilla/ceph-data/journal;
    ceph-deploy osd activate issdm-$i:/mnt/vol1/msevilla/ceph-data:/mnt/ssd1/msevilla/ceph-data/journal;
    ceph-deploy osd activate issdm-$i:/mnt/vol2/msevilla/ceph-data:/mnt/ssd2/msevilla/ceph-data/journal;
    ceph-deploy osd activate issdm-$i:/mnt/vol3/msevilla/ceph-data:/mnt/ssd3/msevilla/ceph-data/journal;
done
echo

echo "Starting MDSs on $MDSs"
ceph osd pool create cephfs_data $PGs
ceph osd pool create cephfs_metadata $PGs
ceph osd pool set cephfs_data size 1
ceph osd pool set cephfs_metadata size 1
ceph fs new sevilla_fs cephfs_metadata cephfs_data

for i in $MDSs; do
    ssh issdm-$i "  sudo mkdir -p /var/lib/ceph/bootstrap-mds /var/lib/ceph/mds $OUT/mds;"
    ceph-deploy mds create issdm-$i
    sleep 1
done
echo

if [ $UNSTABLE -eq 1 ]; then
    echo "Setting tunables"
    sudo ceph osd crush tunables legacy
    sudo ceph osd crush rule rm erasure_ruleset
    sudo ceph osd pool set rbd hashpspool false
    sudo ceph osd pool set cephfs_metadata hashpspool false
    sudo ceph osd pool set cephfs_data hashpspool false
    echo
fi

echo "Going to sleep while the cluster initializes..."
sleep 60
echo "Checking status..."
sudo ceph -s

echo "Setting up clients on $CLIENTs"
sudo chown msevilla:msevilla -R /mnt/vol2/msevilla
rm -r $OUT/
mkdir -p $OUT/status
sudo ceph -s > $OUT/status/status
sudo cp /etc/ceph/ceph.conf $OUT/status/
ceph --version > $OUT/status/version

echo "Starting the clients"
j=0
for i in $CLIENTs; do
    echo -e "\t issdm-$i"
    ssh issdm-$i "  mkdir -p $OUT/client;"
    #                (sudo ceph-fuse /mnt/cephfs -d) > $OUT/client/client$j 2>&1 &"
    #ssh issdm-$i "  sudo chown -R msevilla:msevilla /mnt/cephfs;"
    j=$(($j+1))
done
echo "Fin."
