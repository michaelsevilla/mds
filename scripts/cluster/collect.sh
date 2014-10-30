#!/bin/bash
# Logs into each MDS and dumps the counters
source config.sh
set -e

# Clear old logs
for MDS in $MDSs; do
    echo "setting up MDS $MDS"
    ssh issdm-$MDS "        rm -r $OUT/perf $OUT/cpu; \
                            mkdir $OUT/perf $OUT/cpu; \
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/"
done
for OSD in $OSDs; do
    echo "setting up OSD $OSD"
    ssh issdm-$OSD "        rm -r $OUT/perf $OUT/cpu; \
                            mkdir $OUT/perf $OUT/cpu; \
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/" >> $LOG 2>&1
done
for CLIENT in $CLIENTs; do
    echo "setting up CLIENT $CLIENT"
    ssh issdm-$CLIENT "     rm -r $OUT/perf $OUT/cpu; \
                            mkdir $OUT/perf $OUT/cpu; \ 
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/" >> $LOG 2>&1
done

i=0
echo "m = mds, o = osd, c = client, a = admin"
while true; do
    echo -en "$i\t"
    for MDS in $MDSs; do
        ssh issdm-$MDS "    sudo ceph --admin-daemon $SOCKET perf dump >> $OUT/perf/$MDS-$i; \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i mds >> $OUT/perf/mds-issdm-$MDS.timing; \
                            $SCRIPTS/parse_all_perf.py $OUT/perf/$MDS-$i objecter >> $OUT/perf/objecter-issdm-$MDS.timing;"
                            #echo `date` > $OUT/cpu/$MDS-$i.image; \
                            #echo `date` > $OUT/cpu/$MDS-$i.symbol;"
                            #(top -d 0.5 -n 3 -b > $OUT/cpu/$MDS-$i.proc &); \
                            #sudo opreport -t 0.5 >> $OUT/cpu/$MDS-$i.image 2>/dev/null; \
                            #sudo opreport -t 0.5 -l >> $OUT/cpu/$MDS-$i.symbol 2>/dev/null; \
                            #sudo opcontrol --reset > /dev/null;" 
        echo -n "m"
    done
    for OSD in $OSDs; do
        ssh issdm-$OSD "    sudo ceph --admin-daemon $OSDSOCKET perf dump >> $OUT/perf/$OSD-$i; "
                            #echo `date` > $OUT/cpu/$OSD-$i.image; \
                            #echo `date` > $OUT/cpu/$OSD-$i.symbol;"
                            #(top -d 0.5 -n 3 -b > $OUT/cpu/$OSD-$i.proc &); \
                            #sudo opreport -t 0.5 >> $OUT/cpu/$OSD-$i.image 2>/dev/null; \
                            #sudo opreport -t 0.5 -l >> $OUT/cpu/$OSD-$i.symbol 2>/dev/null; \
                            #sudo opcontrol --reset > /dev/null;" 
        echo -n "o"
    done
    j=0
    for CLIENT in $CLIENTs; do
        ssh issdm-$CLIENT " (top -d 0.5 -n 3 -b > $OUT/cpu/$CLIENT-$i.proc &); \
                            tail -10 $OUT/client/client$j | $SCRIPTS/parse_client.py >> $OUT/client/client.timing;"
        j=$((j+1))
        echo -n "c"
    done

    sudo ceph -s > $OUT/status/status-$i
    sudo ceph osd pool stats > $OUT/status/statpools-$i
    echo "a"

    i=$((i+1))
    sleep $INTERVAL
done

