mds
====
Author: Michael Sevilla\n
Date: 10-24-2014\n
Institution: UC Santa Cruz\n
Email: msevilla@ucsc.edu\n

Work on the Ceph MDS balancer. These are source files changed for DIMPLE. This isn't a self-contained repo (i.e., it won't compile on its own).\n

TODO:\n
1. client utilization: we suspect they are doing more work and sending less requests. This lowers overall throughput but also lowers reply latency for the MDS (sending twice as much but replying faster per requrest).\n
2. mds memory: what is using memory? Look at logging and gdb dump to figure out how much state is kept in memory. What data structures are sucking up memory?\n
3. consequences of revoking capability: why does this improve the efficiency of the MDS?\n

End file
