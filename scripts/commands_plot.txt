# To plot the reply rate
for i in {0..20}; do parse_perf.py 5-$i mds reply_latency >> reply_issdm-5; done
parse_replyl.py reply_issdm-5 ops-per-second >> replyt_issdm-5
parse_replyl.py reply_issdm-5 latency >> replyl_issdm-5
