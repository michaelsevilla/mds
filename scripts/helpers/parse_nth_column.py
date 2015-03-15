#!/usr/bin/python
import os, sys

if len(sys.argv) < 2:
    print "Take a list of files and a column # and concatenate them into one array."
    print "USAGE:", sys.argv[0], "<column> <file1> [<column> <file2> ...]"
    print "- Note: the column numbering is zero based"
    sys.exit(0)

pairs = sys.argv[1]
pairs = pairs.split()
avg = False
if len(sys.argv) > 2:
    avg = True
if len(pairs) % 2 == 1: 
    print "Uh oh - all files do not have a column specified; len(pairs) =", len(pairs)
    sys.exit(0)

fs = []
cols = []
for i in range(0, len(pairs)):
    if i % 2: fs.append(pairs[i])
    else: cols.append(pairs[i])

openfiles = []
for f in fs:
    # openfile is a (fd, [row values]) tuple
    openfiles.append((open(f), []))

# populate the openfile dict
i = 0
for f in openfiles:
    for line in f[0]:
        if "#" not in line:
            words = line.split()
            try:
                f[1].append(words[int(cols[i])])
            except:
                break
    i += 1

if avg:
    vals = [] 
    for f in openfiles:
        for val in f[1]: 
            if float(val) > 0.1: 
                vals.append(float(val))
        # get rid of the end/beginning of job
        vals.remove(min(vals))
        vals.remove(min(vals))
        print str(sum(vals) / len(vals)), 
    print "\n"
else:
    for val in range(0, len(openfiles[0][1])):
        for f in openfiles:
            try:
                print f[1][val],
            except:
                break
        print "\n",

for f in openfiles: f[0].close()
    
