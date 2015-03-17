#!/usr/bin/python

import sys,os,shutil
from subprocess import call

if len(sys.argv) < 3:
    print "Create a graphviz input file that reflexts the subtree loads"
    print "USAGE:", sys.argv[0], "<file> <depth>"
    sys.exit(0)

if os.path.exists("./subtrees"): shutil.rmtree("./subtrees")
os.mkdir("./subtrees")
if os.path.exists("./out"): shutil.rmtree("./out")
os.mkdir("./out")

depth = 2
if len(sys.argv) > 2: depth = int(sys.argv[2])
# depth counts from 0, root is 1, less than equal
depth += 3
f = open(sys.argv[1], "r")
nfile = 0
out = open("./subtrees/iteration-" + str(nfile) + ".dat", "w")
out.write("digraph BST { node [fontname=\"Arial\"];\n")

count = 0
total = 0
subtrees = []
for line in f:
    # if new subtree reading
    if "[Lua5.2]" in line and count != 0:
        count = 0
        nfile += 1
        out.write("}\n")
        out.close() 
        out = open("./subtrees/iteration-" + str(nfile) + ".dat", "w")
        out.write("digraph BST { node [fontname=\"Arial\"];\n")

    # if there is a subtree reading
    if "root" in line:
        path = line.split()[5].split('/')
        # hack
        if len(path) > 2: path[2] = "job"
        metaload = float(line.split()[7].split(']')[0])
        if path[1] == "root" and len(path) == 2: total = metaload
        if len(path) <= depth and total > 0:
            count += 1
            parent = path[len(path) - 2]
            leaf = path[len(path) - 1]
            #if len(parent) > 6: parent = parent[0:6] + "."
            #if len(leaf) > 6: leaf = leaf[0:6] + "."
            heat = hex(int(abs(255.0 * (metaload/total) - 255))).split('x')[1]
            if len(heat) == 1: heat += "0"
            out.write("\t\"" + leaf + "\" [style=filled, fillcolor=\"#FF" + heat + heat + "\"];\n")
            if leaf != "root":
                if nfiles == 0: out.write("\t\"" + parent + "\" -> \"" + leaf + "\";\n")
                else: out.write("\t\"" + parent + "\" -> \"" + leaf + "\" [color=\"#FFFFFFFF]\";\n")

f.close()
data_files = os.listdir("./subtrees")
for f in data_files:
    call(["dot", "-Tpng", "./subtrees/" + f, "-o", "./out/" + f[0:len(f)-3] + "png"])
    
print "Done! Your output is in the ./subtrees directory."
out.close()            
