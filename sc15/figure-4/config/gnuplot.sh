set output '| ps2pdf - ./graph.pdf'
data0 = "./data/run0-thruput"
data1 = "./data/run1-thruput"
data2 = "./data/run2-thruput"
data3 = "./data/run3-thruput"
data4 = "./data/run4-thruput"
data5 = "./data/run5-thruput"

# line color and styles
set style data linespoints
set pointsize 2
set style line 1 lt 1 lw 2.5 pt 1 ps 1 lc rgb "red"
set style line 2 lt 1 lw 5 pt 9 ps 1 lc rgb "green"
set style line 3 lt 1 lw 2.5 pt 7 ps 1 lc rgb "blue"
set style line 4 lt 1 lw 2.5 pt 4 ps 1 lc rgb "black"
set style line 5 lt 4 lw 2.5 pt 5 ps 1 lc rgb "magenta"
set style line 6 lt 3 lw 6 pt 6 ps 1 lc rgb "purple"
set style line 7 lt 5 lw 2.5 pt 7 ps 1 lc rgb "orange"
set style line 100 lt 1 lw 2.5 pt 7 ps 0 lc rgb "purple"
set style line 200 lt 1 lw 2.5 pt 7 ps 0 lc rgb "green"

# fonts
set term postscript enhanced color "Helvetica,22"
set font "Helvetica, 24"
set key font "Helvetica, 18"
set title font "Helvetica, 24"
set xtics font "Helvetica, 24"
set ytics font "Helvetica, 24"
set xlabel font "Helvetica, 24" offset -2
set ylabel font "Helvetica, 34" offset -2
set y2label font "Helvetica, 34" offset -2

# x and y axis configurables
set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
set format y "%.0s%c" 
set yrange[0:6000]
set ytics 2000, 2000

# create 4 separate graphs on the same canvas
set multiplot layout 4,1 
set style fill pattern 1 border
set rmargin 1 
set tmargin 0
set bmargin 1
set lmargin 6

# plot 1: run 5
set key right vertical
unset xtics
set xrange['22:25:59':'22:35:59']
plot \
    data5 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data5 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data5 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"
unset key

# plot 2: run 2
set ylabel "req/s"
set xrange['16:00:06':'16:10:06']
plot \
    data2 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data2 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data2 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

# plot 3: run 3
set ylabel "Metadata"
set xrange ['20:52:03':'21:02:03']
plot \
    data3 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data3 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data3 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"
unset ylabel

# plot 4: run 4
set xlabel "Time (minutes)" offset 0,1
set xrange['22:09:52':'22:19:52']
set xtics ("1" '22:10:52', "2" '22:11:52', "3" '22:12:52', "4" '22:13:52', "5" '22:14:52', "6" '22:15:52', "7" '22:16:52', "8" '22:17:52', "9" '22:18:52', "10" '22:19:52')
plot \
    data4 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data4 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data4 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

unset multiplot
