#!/bin/bash
#set -e

if [ $# -lt 2 ]; then
    echo -e "USAGE: $0 <mon|mds|osd> <config file>"
    exit
fi

DAEMON=$1
CONFIG=$2
CONFDIR=`dirname $CONFIG`
HOST=`hostname`

source $CONFIG
LOG="$OUT/dump-daemons/dump-daemon-$DAEMON.log" >> $LOG 2>&1

sudo chown -R msevilla:msevilla /mnt/vol2/msevilla/ceph-logs/* >> $LOG 2>&1
mkdir -p $OUT/dump-daemons $OUT/osd/perf $OUT/osd/cpu $OUT/mds/perf $OUT/mds/cpu $OUT/mon $OUT/config $OUT/client >> $LOG 2>&1
echo "$DAEMON daemon started at `date`" > $LOG
echo "config: $CONFIG" >> $LOG
echo "out: $OUT" >> $LOG 
echo "log: $LOG" >> $LOG 
echo "hostname: $HOST" >> $LOG 
echo "===================" >> $LOG

echo "... cleaning up" >> $LOG
sudo $SCRIPTS/cleanup.sh osd >> $LOG 2>&1
sudo pkill collectl >> $LOG 2>&1

if [ "$DAEMON" == "mon" ]; then
    echo "--- SETTING UP MON $HOST" >> $LOG
    cp $CONFDIR/* $OUT/config/ >> $LOG 2>&1
elif [ "$DAEMON" == "mds" ]; then
    echo "--- SETTING UP MDS $HOST" >> $LOG
    echo "...  dumping MDS config" >> $LOG
    sudo ceph --admin-daemon /var/run/ceph/ceph-mds*.asok config show > $OUT/config/mds.json 2>&1
    
    echo "... launching collectl" >> $LOG
    sudo pkill collectl >> $LOG 2>&1
    sudo collectl -o z -D -P -i 10 -f $OUT/mds/cpu/ >> $LOG 2>&1
elif [ "$DAEMON" == "osd" ]; then
    echo "SETTING UP OSD $HOST" >> $LOG
    echo "... launching collectl" >> $LOG
    sudo collectl -o z -D -P -i 10 -f $OUT/osd/cpu/ >> $LOG 2>&1
fi

i=0
while true; do
    echo -en "$i... " >> $LOG 
    if [ "$DAEMON" == "mon" ]; then
        sudo ceph -s > $OUT/mon/status-$i
        sudo ceph osd pool stats > $OUT/mon/statpools-$i
        rados df > $OUT/mon/radosdf-$i
    elif [ "$DAEMON" == "mds" ]; then
        sudo ceph --admin-daemon $SOCKET perf dump >> $OUT/mds/perf/$HOST-$i
        head -n -2 $OUT/mds/perf/$HOST-$i > $OUT/mds/perf/tmp
        DATE=`date`
        echo ",\"time\": \"$DATE\"}" >> $OUT/mds/perf/tmp
        mv $OUT/mds/perf/tmp $OUT/mds/perf/$HOST-$i
        (top -d 0.5 -n 3 -b > $OUT/mds/cpu/$HOST-$i.proc &)
    fi
    i=$((i+1))
    sleep $INTERVAL
done
