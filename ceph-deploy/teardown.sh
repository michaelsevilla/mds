#!/bin/bash
# Tear down old cluster
source config/cluster.sh

echo -n "I'm about to tear down the Ceph cluster, are you sure [y/n]? "
read ans
if [ "$ans" == "y" ]; then
    if [ $UNINSTALL -eq 1 ]; then 
        echo "Uninstalling on all nodes: $ALL"
        for i in $ALL
        do
            ceph-deploy purge issdm-$i;
            ceph-deploy purgedata issdm-$i;
            ceph-deploy purge issdm-$i;
            ceph-deploy purgedata issdm-$i;
            sudo dpkg --remove ceph-lua; 
            sudo dpkg --purge librbd1;
            sudo apt-get remove -y librbd1 ceph-fuse; 
        done
        echo
    fi
    
    ./stop.sh
    ceph-deploy forgetkeys;
    
    echo "Stopping MDSs..."
    for i in $MDSs; do
        echo -e "\tissdm-$i"
        ssh issdm-$i "  sudo stop ceph-mds id=issdm-$i; \
                        sudo opcontrol --deinit;" > $LOG 2>&1
    done
    echo
    
    echo "Stopping OSDs..."
    for i in $OSDs; do
        echo -e "\tissdm-$i"
        ssh issdm-$i "  /user/msevilla/ceph-deploy/job-scripts/cleanup-osd.sh; \
                        " >> $LOG 2>&1
    done
    echo
    
    echo "Stopping MONs..."
    for i in $MONs; do
        echo -e "\tissdm-$i"
        ssh issdm-$i "  sudo stop ceph-mon id=issdm-$i" >> $LOG 2>&1
    done
    echo
    
    echo "Checking for straggler processes..."
    for i in $ALL; do
        echo -e "\tissdm-$i"
        ssh issdm-$i "  sudo stop ceph-all; \
                        sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*; \
                        sudo rm -r --one-file-system /mnt/ssd1/msevilla/* /mnt/ssd2/msevilla/* /mnt/ssd3/msevilla/*; \
                        sudo rm -r --one-file-system /mnt/vol1/msevilla/* /mnt/vol2/msevilla/* /mnt/vol3/msevilla/*;" >> $LOG 2>&1
        ssh issdm-$i "  ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
    done 
    echo
fi
