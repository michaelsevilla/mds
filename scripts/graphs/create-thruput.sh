file = "create-throughput"
data0 = "./data/req_thruput0"

load "/home/msevilla/mds/scripts/graphs/header.gnu"
set output '| ps2pdf - ./images/'.file.'.pdf'

set multiplot layout 2,1 title "CephFS request load balancer" font "Helvetica, 36"
#unset key
set style fill pattern 1 border
set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
set font "Helvetica, 24"
set xtics font "Helvetica, 14"
set ytics font "Helvetica, 14"

# plot 1: thruput request balancer
set key top right font "Helvetica, 24"
#set xrange['14:31:23':'14:41:23']
set xtics("2" '14:33:23', "4" '14:35:23', "6" '14:37:23', "8" '14:39:23', "10" '14:41:23')
set ylabel "Metadata req/s" 
set format y "%.0s%c"
set yrange[0:70000]
set ytics 20000, 20000
plot \
    data0 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS2", \
    data0 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS1", \
    data0 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS0"

# plot 2: thruput cpu balancer
#set title "CPU load balancer"
set notitle
#set xrange['14:52:02':'15:02:02']
set xtics("2" '14:54:02', "4" '14:56:02', "6" '14:58:02', "8" '15:00:02', "10" '15:02:02')
set ylabel "Metadata req/s"
set format y "%.0s%c"
set yrange[0:70000]
set ytics 20000, 20000
plot \
    data0 u 2:($3 + $4 + $5)  with filledcurves fill pattern 4 ls 1 title "MDS 2", \
    data0 u 2:($3 + $4)       with filledcurves fill pattern 5 ls 3 title "MDS 1", \
    data0 u 2:3               with filledcurves fill pattern 2 ls 4 title "MDS 0"

# plot 3: cpu request balancer 
#set notitle
#set xrange['14:32:10':'14:42:10']
#set xtics("2" '14:34:10', "4" '14:36:10', "6" '14:38:10', "8" '14:40:10', "10" '14:42:10')
#set ylabel "CPU utilization" font "Helvetica, 24"
#set format y "%.0s%%"
#set yrange[0:25]
#set ytics 10, 10
#set y2label
#set xlabel "Time (minutes)"
#plot \
#    data3 u 2:5 ls 1 lt 1 title "MDS2", \
#    data3 u 2:4 ls 3 lt 2 title "MDS1", \
#    data3 u 2:3 ls 4 lt 3 title "MDS0"

# plot 4: cpu cpu balancer
#set notitle
#set xrange['14:53:40':'15:01:40']
#set xtics("5" '14:58:40', "10" '15:03:40')
#set ylabel "CPU utilization" font "Helvetica, 14"
#set format y "%.0s%%"
#set yrange[0:50]
#set ytics 20, 20
#plot \
#    data1 u 2:5 ls 1 title "MDS 2", \
#    data1 u 2:4 ls 3 title "MDS 1", \
#    data1 u 2:3 ls 4 title "MDS 0"

# plot the legend
#unset origin
#unset border
#unset tics
#unset label
#unset arrow
#unset title
#unset object
#set size 2,2
#set key box
#unset ylabel
#unset xdata
#set key below horizontal nobox
#set key at screen 0.5,screen 0 
#set xrange [-1:1]
#set yrange [-1:1]
#plot data0 with filledcurves fill pattern 2 ls 4 title 'MDS0', \
#     data0 with filledcurves fill pattern 5 ls 3 title 'MDS1', \
#     data0 with filledcurves fill pattern 4 ls 1 title 'MDS2'

unset multiplot

