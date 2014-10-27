#!/usr/bin/python
import sys
import json
from datetime import time, datetime

if len(sys.argv) < 3:
    print "I need a perf counter file to parse and component"
    sys.exit(0)

l = 0
f = open(sys.argv[1])
c = sys.argv[2]
if len(sys.argv) > 3:
    l = sys.argv[3]


time = datetime.now()
perf_counters = json.load(f)

if l == "legend":
    print "# date,time,",
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int):
                    sys.stdout.write(i + ",")
    count = 3
    print "\n# 1,2,",
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int):
                    sys.stdout.write(str(count) + ",")
                    count = count + 1
    count = 3
    print "\n",
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int):
                    sys.stdout.write("# " + str(count) + " " + i + "\n")
                    count = count + 1
    print "\n"
elif l == "replyl":
    print time,
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], dict) and i == "replyl":
                    reply = perf_counters[component][i]
                    print reply["avgcount"], reply["sum"]
else:
    print time,
    for component in perf_counters:
        if c == component:
            counters = perf_counters[component]
            for i in counters:
                if isinstance(perf_counters[component][i], int): 
                    print perf_counters[component][i],
f.close()
