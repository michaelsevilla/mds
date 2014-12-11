#!/bin/bash
# Tear down old cluster
source config.sh

echo "I'm about to tear down the Ceph cluster, are you sure [y/n]?"
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
    
    osd=0
    echo "Stopping OSDs..."
    for i in $OSDs; do
        echo -e "\tissdm-$i"
        ssh issdm-$i "  sudo stop ceph-osd id=$osd" >> $LOG 2>&1
        osd=$(($osd+1))
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
                        sudo chown msevilla:msevilla -R /var/lib/ceph /var/log/ceph /etc/ceph /mnt/vol1/msevilla/ceph-data; \
                        sudo rm -r --one-file-system /var/lib/ceph/* /var/log/ceph/* /etc/ceph/*; \
                        sudo rm -r --one-file-system /mnt/vol1/msevilla/ceph-data/* /mnt/vol2/msevilla/ceph-logs/* /mnt/vol3/msevilla/ceph-data/*;" >> $LOG 2>&1
        ssh issdm-$i "  ps aux | grep ceph | grep \"fuse\|mds\|osd\|mon\" | grep -v \"grep\""
    done 
    echo
fi
