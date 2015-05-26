#!/bin/bash
set -e
source /user/msevilla/ceph-deploy/config.sh

if [ $# -lt 1 ]; then 
    echo "USAGE: $0 <output dir>"
    exit 1
fi
OUTPUTDIR=$1
echo "spitting to $OUTPUTDIR"

if [ ! -d $OUTPUTDIR ]; then
    mkdir $OUTPUTDIR
fi

for i in 0 1 2; do
    echo "------ resetting cluster"
    ./reset.sh
    sleep 60
    echo "------ ... done resetting cluster"
    
    echo "------ configuring MDSs"
    ./cluster.sh MDSs "/user/msevilla/ceph-deploy/config_mds_none.sh"
    #HEAD=`ceph -s | grep mds | awk '{print $5}' | awk -F"," '{print $1}' | awk -F"=" '{print $2}'`
    #echo "------ configuring head: $HEAD"
    #ssh $HEAD "/user/msevilla/ceph-deploy/config_mds1.sh"
    echo "------ ... done configuring MDSs"
    
    echo "------ mount some clients"
    ./cluster.sh CLIENTs "/user/msevilla/ceph-deploy/job-scripts/mount-client.sh"
    echo "------ ... done mounting clients"
    
    echo "------ launching run"
    ./run.sh > /dev/null 2>&1 &
    sleep 30
    echo "... zzz 30"
    sleep 30
    echo "... zzz 60"
    sleep 30
    echo "... zzz 1:30"
    sleep 30
    echo "... zzz 2:00"
    sleep 30
    echo "... zzz 2:30"
    echo "------ ... done launching"
    
    #echo "------ lets prepare the job"
    #job-scripts/prepare-job.sh 
    echo "------ lets prepare the MDSs"
    ./cluster.sh MDSs "/user/msevilla/ceph-deploy/config_mds.sh"
    echo "------ lets start the job `date`"
    job-scripts/start-job.sh
    #echo "------ lets start the sepdir creates `date`"
    #for i in $CLIENTs; do
    #    ssh issdm-$i "/user/msevilla/programs/mdtest/mdtest -F -C -n 100000 -d /mnt/cephfs/dir-$i >/mnt/vol2/msevilla/ceph-logs/client/client-$i.log 2>&1" &
    #done
    echo "------ .... done - going to sleep now"
    #wait
    
    sleep 60
    #sleep 600
    #echo "------ lets run some lss"
    #job-scripts/finish-job.sh
    
    echo "------ writing results"
    sudo pkill run.sh
    ./stop.sh $OUTPUTDIR/run$i
    echo "------ ... done writing"
done
#ssh issdm-0 "mpirun --host issdm-0,issdm-7,issdm-11,issdm-21 /user/msevilla/programs/mdtest/mdtest -n 100000 -F -C -d /mnt/cephfs/shared > /mnt/vol2/msevilla/ceph-logs/client/clients.log 2>&1"
