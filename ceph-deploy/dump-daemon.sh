#!/bin/bash
#set -e

if [ $# -lt 2 ]; then
    echo -e "USAGE: $0 <mon|mds|osd> <config file>"
    exit
fi

DAEMON=$1
CONFIG=$2
source $CONFIG
LOG="$OUT/dump-daemons/dump-daemon-$DAEMON.log 2>&1"

# Create log directories
mkdir $OUT/dump-daemons
echo "$DAEMON daemon started at `date`" > $LOG
if [ "$DAEMON" == "mon" ]; then
    echo "--- setting up MON $MON" >> $LOG
    mkdir $OUT/perf $OUT/cpu $OUT/status $OUT/config $OUT/client >> $LOG
    cp $CONFIG $OUT/config/cluster.sh >> $LOG
elif [ "$DAEMON" == "mds" ]; then
    echo "--- setting up MDS $MDS" >> $LOG
    mkdir $OUT/perf $OUT/cpu $OUT/status >> $LOG
    sudo ceph --admin-daemon /var/run/ceph/ceph-mds*.asok config show > $OUT/status/mds.config
    sudo pkill collectl >> $LOG
    sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/ >> $LOG
    sudo $SCRIPTS/cleanup.sh osd >> $LOG
fi
exit

for OSD in $OSDs; do
    echo "setting up OSD $OSD"
    echo "--- setting up OSD $OSD" >> $LOG
    ssh issdm-$OSD "        mkdir $OUT/perf $OUT/cpu; \
                            sudo -s \"/user/msevilla/ceph-deploy/job-scripts/cleanup-caches.sh\"; \
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/" >> $LOG 2>&1
done

for CLIENT in $CLIENTs; do
    echo "setting up CLIENT $CLIENT"
    echo "--- setting up CLIENT $CLIENT" >> $LOG 
    if [ $COLOCATED_CLIENTS -eq 0 ]; then 
        ssh issdm-$CLIENT " mkdir $OUT/perf $OUT/cpu /mnt/vol2/msevilla/ceph-logs/client; \
                            sudo -s \"/user/msevilla/ceph-deploy/job-scripts/cleanup-caches.sh\"; \
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/" >> $LOG 2>&1
    else
        ssh issdm-$CLIENT " mkdir $OUT/perf $OUT/cpu /mnt/vol2/msevilla/ceph-logs/client;" >> $LOG 2>&1
    fi
done

sudo chown -R msevilla:msevilla /mnt/vol2/msevilla/ceph-logs/

i=0
echo "m = mds, o = osd, c = client, a = admin"
while true; do
    echo -en "$i\t"
    for MDS in $MDSs; do
        ssh issdm-$MDS "    sudo ceph --admin-daemon $SOCKET perf dump >> $OUT/perf/$MDS-$i; \
                            head -n -2 $OUT/perf/$MDS-$i > $OUT/perf/tmp; \
                            echo ',\"time\": \"`date`\"}' >> $OUT/perf/tmp; \
                            mv $OUT/perf/tmp $OUT/perf/$MDS-$i; \
                            (top -d 0.5 -n 3 -b > $OUT/cpu/$MDS-$i.proc &); \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i mds >> $OUT/perf/mds-issdm-$MDS.timing; \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i objecter >> $OUT/perf/objecter-issdm-$MDS.timing; \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i mds_mem >> $OUT/perf/mds_mem-issdm-$MDS.timing; \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i mds_log >> $OUT/perf/mds_log-issdm-$MDS.timing;"
        echo -n "m"
    done

    sudo ceph -s > $OUT/status/status-$i
    sudo ceph osd pool stats > $OUT/status/statpools-$i
    rados df > $OUT/status/radosdf-$i
    echo "a"

    i=$((i+1))
    sleep $INTERVAL
done

