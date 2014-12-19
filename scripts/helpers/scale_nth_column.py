#!/usr/bin/python
import os, sys

if len(sys.argv) < 4:
    print "Scale the nth column of an input file."
    print "USAGE:", sys.argv[0], "<file> <column> <scale>"
    print "- Note: the column numbering is zero based"
    sys.exit(0)

f = open(sys.argv[1])
col = int(sys.argv[2])
scale = float(sys.argv[3])

for line in f:
    words = line.split()
    words[col] = float(words[col]) * scale
    for w in words:
        print w,
    print "\n",
