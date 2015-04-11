HELPERS="/home/msevilla/mds/scripts/helpers"
SAMPLES=0
for i in {0..1000}; do 
    if [ -a 15-$i ]; then
        #echo -n "file 15-$i replies ="; 
        #cat 15-$i | grep "\"reply\"";
        echo -n "15-$i "
        SAMPLES=$i
    fi
done
echo ""
echo "found $SAMPLES samples"
echo "making replyl files for $MDSs"
for MDS in $MDSs; do
    for i in $(seq 0 $SAMPLES); do parse_perf.py $MDS-$i mds reply_latency >> reply_issdm-$MDS; done
    #$HELPERS/delete_dups.py mds-issdm-$MDS.timing > timing
    $HELPERS/parse_replyl.py reply_issdm-$MDS ops-per-second | sed 's/-[0-9][0-9]*/0/g' >> replyt_issdm-$MDS
    $HELPERS/parse_replyl.py reply_issdm-$MDS latency >> replyl_issdm-$MDS
    $HELPERS/parse_nth_column.py "0 reply_issdm-$MDS 1 replyl_issdm-$MDS 2 replyl_issdm-$MDS 2 replyt_issdm-$MDS" > replyc_issdm-$MDS
    rm replyl_issdm-$MDS replyt_issdm-$MDS  reply_issdm-$MDS
    echo "... done with $MDS"
done
