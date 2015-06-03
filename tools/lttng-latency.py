#!/usr/bin/python3
# Adapted from http://noahdesu.github.io/2014/06/01/tracing-ceph-with-lttng-ust.html
import sys
import numpy
from babeltrace import *
import time
import math
import getopt

# This is for ceph version 9.0.0-928-g98d1c10 (98d1c1022c098b98bdf7d30349214c00b15cffec)
requests = {
        int("0x00100", 16) : {"op" : "CEPH_MDS_OP_LOOKUP"}        ,
        int("0x00101", 16) : {"op" : "CEPH_MDS_OP_GETATTR"}       ,
        int("0x00102", 16) : {"op" : "CEPH_MDS_OP_LOOKUPHASH"}    , 
        int("0x00103", 16) : {"op" : "CEPH_MDS_OP_LOOKUPPARENT"}  , 
        int("0x00104", 16) : {"op" : "CEPH_MDS_OP_LOOKUPINO"}     , 
        int("0x00105", 16) : {"op" : "CEPH_MDS_OP_LOOKUPNAME"}    , 
        int("0x01105", 16) : {"op" : "CEPH_MDS_OP_SETXATTR"}      , 
        int("0x01106", 16) : {"op" : "CEPH_MDS_OP_RMXATTR"}       , 
        int("0x01107", 16) : {"op" : "CEPH_MDS_OP_SETLAYOUT"}     , 
        int("0x01108", 16) : {"op" : "CEPH_MDS_OP_SETATTR"}       , 
        int("0x01109", 16) : {"op" : "CEPH_MDS_OP_SETFILELOCK"}   , 
        int("0x00110", 16) : {"op" : "CEPH_MDS_OP_GETFILELOCK"}   , 
        int("0x0110a", 16) : {"op" : "CEPH_MDS_OP_SETDIRLAYOUT"}  , 
        int("0x01201", 16) : {"op" : "CEPH_MDS_OP_MKNOD"}         ,
        int("0x01202", 16) : {"op" : "CEPH_MDS_OP_LINK"}          , 
        int("0x01203", 16) : {"op" : "CEPH_MDS_OP_UNLINK"}        , 
        int("0x01204", 16) : {"op" : "CEPH_MDS_OP_RENAME"}        ,
        int("0x01220", 16) : {"op" : "CEPH_MDS_OP_MKDIR"}         , 
        int("0x01221", 16) : {"op" : "CEPH_MDS_OP_RMDIR"}         , 
        int("0x01222", 16) : {"op" : "CEPH_MDS_OP_SYMLINK"}       , 
        int("0x01301", 16) : {"op" : "CEPH_MDS_OP_CREATE"}        , 
        int("0x00302", 16) : {"op" : "CEPH_MDS_OP_OPEN"}          ,
        int("0x00305", 16) : {"op" : "CEPH_MDS_OP_READDIR"}       , 
        int("0x00400", 16) : {"op" : "CEPH_MDS_OP_LOOKUPSNAP"}    , 
        int("0x01400", 16) : {"op" : "CEPH_MDS_OP_MKSNAP"}        , 
        int("0x01401", 16) : {"op" : "CEPH_MDS_OP_RMSNAP"}        , 
        int("0x00402", 16) : {"op" : "CEPH_MDS_OP_LSSNAP"}        , 
        int("0x01403", 16) : {"op" : "CEPH_MDS_OP_RENAMESNAP"}    , 
        int("0x01500", 16) : {"op" : "CEPH_MDS_OP_FRAGMENTDIR"}   , 
        int("0x01501", 16) : {"op" : "CEPH_MDS_OP_EXPORTDIR"}     , 
        int("0x01502", 16) : {"op" : "CEPH_MDS_OP_VALIDATE"}      , 
        int("0x01503", 16) : {"op" : "CEPH_MDS_OP_FLUSH"}
}

# Taken from: https://gordoncluster.wordpress.com/2014/02/13/python-numpy-how-to-generate-moving-averages-efficiently-part-2/
def movingavg(values, window):
    weights = numpy.repeat(1.0, window)/window
    return numpy.convolve(values, weights, 'valid')

def main(argv):
    op = "CEPH_MDS_OP_CREATE"
    window = 10
    trace = -1
    output = -1
    try:
        opts, args = getopt.getopt(argv, "ht:w:o:d:", ["type=", "window=", "output=", "dir="])
    except getopt.GetoptError:
        print(sys.argv[0] + " -t <operation> -w <window> -o <outputfile> -d <LTTng trace dir>", file=sys.stderr)
        sys.exit(0)
    for opt, arg in opts:
        if opt == '-h':
            print("\nPrint out distribution of the request latencies", file=sys.stderr)
            print("\n\tusage: " + sys.argv[0] + " -t <operation> -w <window> -o <outputfile> -d <LTTng trace dir>", file=sys.stderr)
            print("\n\nOperations: ", end=" ", file=sys.stderr)
            for r in requests:
                print(str(r) + " " + requests[r]["op"], end=" ", file=sys.stderr)
            print("\n\n", file=sys.stderr)
            sys.exit(0)
        elif opt in ("-t", "--type"): op = arg
        elif opt in ("-w", "--window"): window = arg
        elif opt in ("-o", "--output"): output = arg
        elif opt in ("-d", "--dir"): trace = arg
    
    if trace == -1 or output == -1:
        print("LTTng trace directory (-d) AND output file (-o) must be specified.\n", file=sys.stderr)
        sys.exit(0)
    
    # initialize some stuff
    traces = TraceCollection()
    ret = traces.add_trace(trace, "ctf")
    inflight = {}; latencies = {}
    start = sys.maxsize; finish = -1
    
    # get the latencies for the specified operation
    count = 1
    for event in traces.events:
        if requests[event["type"]]["op"] == op:
            ts, tid  = event.timestamp, event["tid"]
    
            # get the thread servicing the client request
            if event.name == "mds:req_received":
                inflight[tid] = ts
            elif event.name == "mds:req_replied" or event.name == "mds:req_early_replied":
                # get the first/last timestamp
                if ts < start: start = ts
                if ts > finish: finish = ts

                # add the latency (using the timestamp as key) to the proper bin
                t = time.strftime('%H:%M:%S',  time.localtime(ts/1e9))
                try:
                    if t not in latencies:
                        latencies[t] = {}
                        latencies[t]["all"] = []
                    latencies[t]["all"].append(ts - inflight[tid])
                    del inflight[tid]
                except KeyError:
                    continue
        count += 1
        if count % 10000 == 0: 
            print("... done with " + str(int(count/1000)) + "k events")

    print("... get the average latency for each second time step\n")
    # - there's a lot of copying going on here... but the runs usually take about 10 minutes,
    #   which is only about 600 samples... if we need to do like 6 hours, then this might take
    #   a while
    avgLatencies = []
    times = []
    for k,v in sorted(latencies.items()):
        print("len of " + str(k) + " is " + str(len(v["all"])))
        if v and v["all"]:
            times.append(k)
            avgLatencies.append(numpy.mean(v["all"]))
    
    print("... get the moving averages\n")
    try:
        mvAvg = movingavg(avgLatencies, window)
    except:
        print("Not enough values for a moving average", file=sys.stderr)
        sys.exit(0)

    print("... put the moving average value back into the latencies dictionary\n")
    for i in range(len(times)):
        latencies[times[i]]["mean"] = avgLatencies[i]
        if i < window:
            latencies[times[i]]["mvavg"] = 0
        else:
            latencies[times[i]]["mvavg"] = mvAvg[i - window]
    
    # get the number of requests in that second
    f = open(output, 'w')
    f.write("# time nrequests latency average\n")
    print(  "# time nrequests," +
            " start=" + time.strftime('%H:%M:%S',  time.localtime(start/1e9)) + 
            " finish=" + time.strftime('%H:%M:%S',  time.localtime(finish/1e9)) + "\n")
    prevLat = 0; prevMvAvg = 0
    for ts in range(math.floor(start/1e9) - 1, math.floor(finish/1e9) + 1):
        t = time.strftime('%H:%M:%S',  time.localtime(ts))
        try:
            f.write(str(t) + 
                    " " + str(len(latencies[t]["all"])) + 
                    " " + str(latencies[t]["mean"]/1e6) + 
                    " " + str(latencies[t]["mvavg"]/1e6) + "\n")
            prevLat = latencies[t]["mean"]
            prevMvAvg = latencies[t]["mvavg"]
        except KeyError:
            f.write(str(t) + " 0 " + 
                    " " + str(prevLat/1e6) +
                    " " + str(prevMvAvg/1e6) + "\n")
    f.close()

if __name__ == "__main__":
    main(sys.argv[1:])
