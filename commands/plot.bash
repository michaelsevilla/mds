# To plot the reply rate
export MDS=15
export SAMPLES=20
for i in {0..$SAMPLES}; do parse_perf.py $MDS-$i mds reply_latency >> reply_issdm-$MDS; done
parse_replyl.py reply_issdm-$MDS ops-per-second >> replyt_issdm-$MDS
parse_replyl.py reply_issdm-$MDS latency >> replyl_issdm-$MDS
