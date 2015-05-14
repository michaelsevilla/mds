#! /usr/bin/python

firstfile = 8
lastfile  = 56
shiftX    = 0.1
shiftY    = -0.05
startX    = 0
startY    = -0.15

cmds = []
count = 1
for i in range(firstfile, lastfile + 1): 
    shift = startX + shiftX*count 
    cmds.append("\\node (" + str(i) + ")[xshift=" + str(shift) + "cm]{\includegraphics[width=0.3\\textwidth]{/Users/msevilla/Downloads/out-depth2/iteration-" + str(i) + ".png}};")
    count += 1
for i in reversed(cmds): print i

cmds = []
count = 1
for i in range(firstfile, lastfile + 1):
    shift = startY + shiftY*count 
    cmds.append("\\node (d1-" + str(i) + ")[yshift=" + str(shift) + "cm, xshift=-0.65cm]{\includegraphics[width=0.21\\textwidth]{/Users/msevilla/Downloads/out-depth1/iteration-" + str(i) + ".png}};")
    count += 1
for i in reversed(cmds): print i

print "\\node (0){\includegraphics[width=0.3\\textwidth]{/Users/msevilla/Downloads/out-depth2/iteration-0.png}};"
 
