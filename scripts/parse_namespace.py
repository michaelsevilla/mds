#! /usr/bin/python
import sys

if len(sys.argv) < 2:
    print "@input:  client debug log"
    print "@output: tab-delimted file"
    print "Create a histogram (averaged over time steps) of requests"
    print "USAGE:", sys.argv[0], "<file>"
    sys.exit(0)
f = open(sys.argv[1], "r")

types = {"create", 
         "lookup", 
         "mkdir", 
         "symlink", 
         "getattr", 
         "setattr", 
         "unlink", 
         "symlink",
         "readdir", 
         "rename", 
         "open"}

print "# 1.date 2.time",
i = 3
for t in types: print str(i) + "." + t,; i += 1
print 

reqs = {}
time = "00:00:00"
dirs = {}
path = ""
store = 0
for t in types: reqs[t] = 0
for line in f:
    if "send_request client" in line:
        words = line.split()
        for t in types:
            if t in line:
                reqs[t] += 1
        date = words[0]
        now = words[1].split('.')[0]
        if time != "" and now.split(':')[2] != time.split(':')[2]:
            #print date, now, 
            #for t in types: print reqs[t],
            #print
            for t in types: reqs[t] = 0
            time = now
        if "mkdir" in line: 
            path = words[8]
            print "path=",path
f.close()
