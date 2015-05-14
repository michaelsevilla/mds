#!/usr/bin/python
import sys

f = open(sys.argv[1])
prev = ""
for line in f:
    words = line.split()
    time = words[1].split(":")
    second = time[2].split(".")
    if prev != second[0]:
        print line,
    prev = second[0]
