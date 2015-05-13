file = "create-throughput-runs"
data0 = "./data/run0_3mds_thruput"
data1 = "./data/run1_3mds_thruput"
data2 = "./data/run2_3mds_thruput"
data3 = "./data/run3_3mds_thruput"
data4 = "./data/run4_3mds_thruput"
data5 = "./data/run5_3mds_thruput"

load "/home/msevilla/mds/scripts/graphs/header.gnu"
set output '| ps2pdf - ./graph.pdf'

set multiplot layout 4,1 
#title "CephFS request load balancer" font "Helvetica, 36"
#unset key
set style fill pattern 1 border
set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'

# fonts
set font "Helvetica, 24"
set xtics font "Helvetica, 24"
set ytics font "Helvetica, 24"
set xlabel font "Helvetica, 34" offset -2
set ylabel font "Helvetica, 34" offset -2
set rmargin 1 
set tmargin 0
set bmargin 1
set lmargin 6

# plot 1: run 0
unset xlabel
unset xtics
unset ylabel
set ytics font "Helvetica, 24"
set format y "%.0s%c" 
set yrange[0:6000]
set ytics 2000, 2000

# plot 1: run 5
set key right font "Helvetica, 22"
set xrange['22:25:59':'22:35:59']
plot \
    data5 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data5 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data5 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

# plot 2: run 2
unset key
set xrange['16:00:06':'16:10:06']
set ylabel font "Helvetica, 34" offset -2
set ylabel "req/s"
plot \
    data2 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data2 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data2 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

# plot 3: run 3
set xrange ['20:52:03':'21:02:03']
set ylabel font "Helvetica, 34" offset -2
set ylabel "Metadata"
plot \
    data3 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data3 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data3 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

# plot 4: run 4
unset key
unset ylabel
set ytics font "Helvetica, 24"
set xlabel font "Helvetica, 24"
set xlabel "Time (minutes)" offset 0,1
set xrange['22:09:52':'22:19:52']
set xtics ("1" '22:10:52', "2" '22:11:52', "3" '22:12:52', "4" '22:13:52', "5" '22:14:52', "6" '22:15:52', "7" '22:16:52', "8" '22:17:52', "9" '22:18:52', "10" '22:19:52')
plot \
    data4 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data4 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data4 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

unset multiplot

