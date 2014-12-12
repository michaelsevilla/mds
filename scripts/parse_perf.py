#!/usr/bin/python
import sys
import json
from datetime import time, datetime

if len(sys.argv) < 3:
    print "Convert JSON values to space delimited file (good for graphing)"
    print "USAGE:", sys.argv[0], "<file> <component> (legend|reply_latency|component)"
    print " - legend: for copying and pasting into tailplot"
    print " - reply_latency: parse out the average count and sum" 
    sys.exit(0)

l = 0
f = open(sys.argv[1])
c = sys.argv[2]
if len(sys.argv) > 3:
    l = sys.argv[3]


time = datetime.now()
perf_counters = json.load(f)

if l == "legend":
    print " date time ",
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int):
                    sys.stdout.write(i + " ")
elif l == "reply_latency":
    print time, 
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], dict) and i == "reply_latency":
                    reply = perf_counters[component][i]
                    print reply["avgcount"], reply["sum"]
elif l == "component":
    for component in perf_counters:
        print component,
else:
    print time,
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int): 
                    print perf_counters[component][i],
f.close()
