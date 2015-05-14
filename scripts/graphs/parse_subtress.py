#!/usr/bin/python

import sys,os,shutil
from subprocess import call

debug = False
dont_graph = ["block", "crypt.", "net", "ipc", "sampl.", "usr", "secur.", "sound", "virt", "tools"]

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
        if debug: print "--- NEW FILE!!! ---> " + str(i) + " ---"
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
            if len(parent) > 5: parent = parent[0:5] + "."
            if len(leaf) > 5: leaf = leaf[0:5] + "."
            node = Node(leaf, parent, metaload)
            if debug: print "appending Node(name=" + node.name, "parent=" + node.parent, "metaload=" + str(node.metaload)
            subtrees[i].append(node)
            # check to make sure we have this node in all nodes
            add = True
            for anode in all_nodes:
                if anode.name == node.name: add = False
            if node.name in dont_graph: add = False
            if add: all_nodes.append(node)
f.close()

i = 0
for subtree in subtrees:
    printed = []
    if debug: print "--- NEW FILE!!! ---> " + str(i) + " ---"
    out = open("./subtrees/iteration-" + str(i) + ".dat", "w")
    out.write("digraph BST { node [fontname=\"Arial\"];\n")
    out.write("\t bgcolor=\"transparent\";\n")
    out.write("\t rankdir=\"LR\";\n")
    #out.write("\t nodesep=0.8;\n")
    # fill in the whole tree, substituting current nodes
    for anode in all_nodes:
        node = None
        for pnode in subtree:
            if anode.name == pnode.name: node = pnode

        if node is None:
            node = anode
            if debug: print "Add a blank node: " + node.name
            heatR = "ff"
            heatG = "ff"
            heatB = "ff"
        else: 
            heat = node.metaload/largest_metaload
            if debug: print "Substituting the printed node " +  node.name, "metaload=" + str(node.metaload), "largest=" + str(largest_metaload)
            if heat >= 0.25:  # red to black (255->0)
                heatR = str(hex(int(abs((heat-0.25)*(4/3)*255-255))).split('x')[1])
                heatG = "00"
                heatB = "00"
            else:            # white to red (0->255)
                heatR = "FF"
                heatG = str(hex(int(heat*4*255)).split('x')[1])
                heatB = str(hex(int(heat*4*255)).split('x')[1])
            if len(heatR) == 1: heatR += "0"
            if len(heatG) == 1: heatG += "0"
            if len(heatB) == 1: heatB += "0"
        # hack, no hotspot shadows for these guyes
        if depth > 5 and i != 0 and (node.name == "root" or node.name == "job" or node.name == "linux."):
            out.write("\t\"" + node.name + "\" [style=filled, width=0.8, fixedsize=true, color=\"white\", fillcolor=\"white\", fontcolor=\"white\"];\n")
        else:
            if i == 0: out.write("\t\"" + node.name + "\" [style=filled, width=0.8, fixedsize=true, fillcolor=\"#" + heatR + heatG + heatB + "\"];\n")
            else: out.write("\t\"" + node.name + "\" [style=filled, width=0.8, fixedsize=true, fontcolor=\"#FFFFFF00\", fillcolor=\"#" + heatR + heatG + heatB + "\"];\n")
        if node.name != "root":
            if i ==  0: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\";\n")
            else: out.write("\t\"" + node.parent + "\" -> \"" + node.name + "\" [color=\"#FFFFFF00\"];\n")
        if debug: print "name=" + node.name, "parent=" + node.parent, "heatR=" + heatR, "heatG=" + heatG, "heatB=" + heatB
    i += 1
    out.write("}\n")
    out.close()

# graphviz the data files
for f in os.listdir("./subtrees"): call(["dot", "-Tpng", "./subtrees/" + f, "-o", "./out/" + f[0:len(f)-3] + "png"])

print "Done! Your output is in the ./subtrees directory."
