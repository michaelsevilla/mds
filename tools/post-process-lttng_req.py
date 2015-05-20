#!/usr/bin/python3
# Adapted from http://noahdesu.github.io/2014/06/01/tracing-ceph-with-lttng-ust.html
import sys
import numpy
from babeltrace import *

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

if len(sys.argv) < 2:
    print("@input:  LTTng trace")
    print("@output: request latencies")
    print("Print out distribution of the request latencies")
    print("USAGE:", sys.argv[0], "<file> [window]")
    sys.exit(0)
trace = sys.argv[1]
try:
    window = int(sys.argv[2])
except:
    window = 1

# initialize some stuff
for r in requests:
    requests[r]["latency"] = []
traces = TraceCollection()
ret = traces.add_trace(trace, "ctf")

servicers = {}
for event in traces.events:
    time, addr, type = event.timestamp, event["addr"], event["type"]
    pthread_id  = event["pthread_id"]
    #print(requests[type]["op"] + " " + str(time))
    
    # get the thread servicing the client request
    servicer = (pthread_id, addr)
    if event.name == "mds:req_enter":
        servicers[servicer] = time
    elif event.name == "mds:req_exit":
        try:
            latency = time - servicers[servicer]
            del servicers[servicer]
            #print(requests[type]["op"] + "\t" + str(latency))
            requests[type]["latency"].append(latency)
        except KeyError:
            continue

for r in requests:
    if len(requests[r]["latency"]) > 0:
        # get the regular latencies
        print(requests[r]["op"] + ": ", end="")
        for l in requests[r]["latency"]:
            print(str(l) + " ", end="")
        print("")

        # get the moving average of those latencies
        request_movingavg = movingavg(requests[r]["latency"], window)
        print(requests[r]["op"] + " (mvavg): " + str(request_movingavg))
