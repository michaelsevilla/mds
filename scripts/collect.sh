#!/bin/bash
# Logs into each MDS and dumps the counters
#set -e
OUT="/home/msevilla/code/ceph/src/out"
SCRIPTS="/home/msevilla/code/"
SOCKET="/home/msevilla/code/ceph/src/out"
MDSs="a b c"
INTERVAL=10
i=0

# Clear old logs
echo "setting up MDS $MDS"
rm -r $OUT/perf $OUT/cpu;
mkdir $OUT/perf $OUT/cpu;
echo "killed collectl"
sudo pkill collectl;
echo "starting collectl"
sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/
echo "collectl started"

echo "m = mds, o = osd, c = client, a = admin"
while true; do
    echo -en "$i\t"
    for MDS in $MDSs; do
        sudo ceph --admin-daemon $SOCKET/mds.$MDS.asok  perf dump >> $OUT/perf/$MDS-$i; 
        $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i mds >> $OUT/perf/mds-issdm-$MDS.timing; 
        $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i objecter >> $OUT/perf/objecter-issdm-$MDS.timing;
        echo -n "m"
    done
    echo ""

    i=$((i+1))
    sleep $INTERVAL
done

