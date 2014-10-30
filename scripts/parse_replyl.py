#!/usr/bin/python
import sys
import json
from datetime import time, datetime
if len(sys.argv) < 3:
    print "Convert space delimited file of \"Date time count sum\" into \"Date time reply_latency\"" 
    print sys.argv[0], "<file> <latency|ops-per-second>"
    sys.exit(0)

l = 0
f = open(sys.argv[1])
stat = sys.argv[2]

time = datetime.now()
pcount = 0
psum = 0
for line in f:
    words = line.split()
    count = float(words[2])
    sum = float(words[3])
    if stat == "latency":
        try:
            ans = 1000 * (sum - psum) / (count - pcount)
            if ans and ans < 3:
                print words[0], words[1], ans
            else:
                print words[0], words[1], 0
        except:
            print words[0], words[1], 0
    elif stat == "ops-per-second":
        try:
            print words[0], words[1], count - pcount
        except: 
            print words[0], words[1], 0
    else:
        print "don't know how to parse"
        sys.exit()
    pcount = count
    psum = sum

f.close()
