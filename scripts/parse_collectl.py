#!/usr/bin/python
import os, sys

if len(sys.argv) < 2:
    print "Print out the column headings for collectl tab-delimited file"
    print "USAGE:", sys.argv[0], "<file>"
    sys.exit(0)

fname = sys.argv[1]
count = 1
vals = []
if fname:
    f = open(fname)
    for line in f:
        if "Date Time" in line:
            words = line.split(" ")
            for w in words:
                #print count, w
                vals.append(w)
                count += 1
for v in vals:
    sys.stdout.write(str(v) + " ")

