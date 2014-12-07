MDS=$MDS
HELPERS="/home/msevilla/mds/scripts/helpers"

echo "how many samples?"
read SAMPLES

for i in $(seq 0 $SAMPLES); do parse_perf.py $MDS-$i mds reply_latency >> reply_issdm-$MDS; done
$HELPERS/parse_replyl.py reply_issdm-$MDS ops-per-second >> replyt_issdm-$MDS
$HELPERS/parse_replyl.py reply_issdm-$MDS latency >> replyl_issdm-$MDS
$HELPERS/parse_nth_column.py "0 mds-issdm-$MDS.timing 1 mds-issdm-$MDS.timing 2 replyl_issdm-$MDS 2 replyt_issdm-$MDS" > replyc_issdm-$MDS
rm replyl_issdm-$MDS replyt_issdm-$MDS  reply_issdm-$MDS
