#!/bin/bash
# Logs into each MDS and dumps the counters
source config.sh
#set -e

# Create log directories
for MON in $MONs; do
    echo "setting up MON $MON"
    echo "--- setting up MDS $MDS" >> $LOG
    ssh issdm-$MON "        mkdir $OUT/perf $OUT/cpu $OUT/status $OUT/client; \
                            cp /user/msevilla/ceph-deploy/config.sh $OUT/status/config.sh" > /dev/null 2>&1
    
done
    
for MDS in $MDSs; do
    echo "setting up MDS $MDS"
    echo "--- setting up MDS $MDS" >> $LOG
    ssh issdm-$MDS "        mkdir $OUT/perf $OUT/cpu $OUT/status > /dev/null 2>&1; \
                            sudo ceph --admin-daemon /var/run/ceph/ceph-mds*.asok config show > $OUT/status/mds.config; \
                            sudo pkill collectl; \
                            sudo collectl -o z -D -P -i 10 -f /mnt/vol2/msevilla/ceph-logs/cpu/; \
                            sudo -s \"/user/msevilla/ceph-deploy/job-scripts/cleanup-caches.sh\";" >> $LOG 2>&1
done
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
#./cluster.sh CLIENTs "mount"
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
                            #sudo ceph --admin-daemon $SOCKET session ls >> $OUT/status/$MDS-$i; \
                            #sudo ceph --admin-daemon $SOCKET dump_ops_in_flight >> $OUT/status/$MDS-$i; \
                            #echo `date` > $OUT/cpu/$MDS-$i.image; \
                            #echo `date` > $OUT/cpu/$MDS-$i.symbol;"
                            #sudo opreport -t 0.5 >> $OUT/cpu/$MDS-$i.image 2>/dev/null; \
                            #sudo opreport -t 0.5 -l >> $OUT/cpu/$MDS-$i.symbol 2>/dev/null; \
                            #sudo opcontrol --reset > /dev/null;" 
        echo -n "m"
    done
    #for OSD in $OSDs; do
    #    ssh issdm-$OSD "    sudo ceph --admin-daemon $OSDSOCKET perf dump >> $OUT/perf/$OSD-$i; "
    #                        #echo `date` > $OUT/cpu/$OSD-$i.image; \
    #                        #echo `date` > $OUT/cpu/$OSD-$i.symbol;"
    #                        #(top -d 0.5 -n 3 -b > $OUT/cpu/$OSD-$i.proc &); \
    #                        #sudo opreport -t 0.5 >> $OUT/cpu/$OSD-$i.image 2>/dev/null; \
    #                        #sudo opreport -t 0.5 -l >> $OUT/cpu/$OSD-$i.symbol 2>/dev/null; \
    #                        #sudo opcontrol --reset > /dev/null;" 
    #    echo -n "o"
    #done
    #j=0
    #for CLIENT in $CLIENTs; do
    #    ssh issdm-$CLIENT " (top -d 0.5 -n 3 -b > $OUT/cpu/$CLIENT-$i.proc &); \
    #                        tail -10 $OUT/client/client$j | $SCRIPTS/parse_client.py >> $OUT/client/client.timing;"
    #    j=$((j+1))
    #    echo -n "c"
    #done

    sudo ceph -s > $OUT/status/status-$i
    sudo ceph osd pool stats > $OUT/status/statpools-$i
    rados df > $OUT/status/radosdf-$i
    echo "a"

    #if [ $i -eq 2 ]; then
    #    /user/msevilla/ceph-deploy/job-scripts/start-job.sh        
    #fi

    i=$((i+1))
    sleep $INTERVAL
done

