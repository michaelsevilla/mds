#!/usr/bin/python
import os, sys

if len(sys.argv) < 3:
    print "Take a list of files and a column # and concatenate them into one array."
    print "USAGE:", sys.argv[0], "<column> <list of files>"
    sys.exit(0)

column = sys.argv[1]
files = sys.argv[2]

openfiles = []
timestamps = []
fs = files.split()
for f in fs:
    openfiles.append((open(f), []))

for f in openfiles:
    for line in f[0]:
        if "#" not in line:
            words = line.split()
            f[1].append(words[int(column)])
            timestamps.append(words[0] + " " + words[1])

for val in range(0, len(openfiles[0][1])):
    print timestamps[val],
    for f in openfiles:
        print f[1][val],
    print "\n",
    

for f in openfiles:
    #print "... closing f=",f
    f[0].close()
    
