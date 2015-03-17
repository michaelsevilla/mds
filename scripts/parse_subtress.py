#!/usr/bin/python

import sys,os,shutil
from subprocess import call

debug = False

if len(sys.argv) < 3:
    print "Create a graphviz input file that reflexts the subtree loads"
    print "USAGE:", sys.argv[0], "<file> <depth>"
    sys.exit(0)

class Node:
    def __init__(self, n, p, m):
        self.name = n
        self.parent = p
        self.metaload = m

if os.path.exists("./subtrees"): shutil.rmtree("./subtrees")
os.mkdir("./subtrees")
if os.path.exists("./out"): shutil.rmtree("./out")
os.mkdir("./out")

depth = 2
if len(sys.argv) > 2: depth = int(sys.argv[2])
# depth counts from 0, root is 1, less than equal
depth += 3
f = open(sys.argv[1], "r")

count = 0
total = 0
subtrees = []
i = 0
subtrees.append([])
all_nodes = []
largest_metaload = 0
for line in f:
    # if new subtree reading
    if "[Lua5.2]" in line and count != 0:
        count = 0
        i += 1
        subtrees.append([])

    # if there is a subtree reading
    if "root" in line:
        path = line.split()[5].split('/')
        # hack
        if len(path) > 2: path[2] = "job"
        metaload = float(line.split()[7].split(']')[0])
        if path[1] == "root" and len(path) == 2:
            if metaload > largest_metaload: largest_metaload = metaload
        if len(path) <= depth:
            count += 1
            parent = path[len(path) - 2]
            leaf = path[len(path) - 1]
            #if len(parent) > 6: parent = parent[0:6] + "."
            #if len(leaf) > 6: leaf = leaf[0:6] + "."
            node = Node(leaf, parent, metaload)
            if debug: print "appending Node(name=" + node.name, "parent=" + node.parent, "metaload=" + str(node.metaload)
            subtrees[i].append(node)
            # check to make sure we have this node in all nodes
            add = True
            for anode in all_nodes:
                if anode.name == node.name: add = False
            if add: all_nodes.append(node)
f.close()

i = 0
for subtree in subtrees:
    printed = []
    if debug: print "--- NEW FILE!!! ---> " + str(i) + " ---"
    out = open("./subtrees/iteration-" + str(i) + ".dat", "w")
    out.write("digraph BST { node [fontname=\"Arial\"];\n")
    for node in subtree:
        heat = str(hex(int(abs(255*node.metaload/largest_metaload - 225))).split('x')[1])
        if len(heat) == 1: heat += "0"
        out.write("\t\"" + node.name + "\" [style=filled, fillcolor=\"#FF" + heat + heat + "\"];\n")
        printed.append(node)
        if node.name != "root":
            if i ==  0: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\";\n")
            else: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\" [color=\"#FFFFFFFF\"];\n")
        if debug: print "name=" + node.name, "parent=" + node.parent, "heat=" + heat
    # fill in the rest of the tree
    for node in all_nodes:
        add = True
        for pnode in printed:
            if node.name == pnode.name: add = False
        if add: 
            #heat = str(hex(int(abs(255*node.metaload/largest_metaload - 225))).split('x')[1])
            heat = "ff"
            out.write("\t\"" + node.name + "\" [style=filled, fillcolor=\"#FF" + heat + heat + "\"];\n")
            if node.name != "root":
                if i ==  0: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\";\n")
                else: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\" [color=\"#FFFFFFFF\"];\n")
        else: 
            if debug: "Not adding " +  node.name + "\n"
    i += 1
    out.write("}\n")
    out.close()

# graphviz the data files
for f in os.listdir("./subtrees"): call(["dot", "-Tpng", "./subtrees/" + f, "-o", "./out/" + f[0:len(f)-3] + "png"])

#heat = hex(int(abs(255.0 * (metaload/total) - 255))).split('x')[1]

print "Done! Your output is in the ./subtrees directory."
