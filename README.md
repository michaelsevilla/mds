mds
====
Author: Michael Sevilla  
Date: 10-24-2014  
Institution: UC Santa Cruz  
Email: msevilla@ucsc.edu  


Work on the Ceph MDS balancer. These are source files changed for DIMPLE. This isn't a self-contained repo (i.e., it won't compile on its own).

TODO:  
1. client utilization: we suspect they are doing more work and sending less requests. This lowers overall throughput but also lowers reply latency for the MDS (sending twice as much but replying faster per requrest).  
2. mds memory: what is using memory? Look at logging and gdb dump to figure out how much state is kept in memory. What data structures are sucking up memory?  
3. consequences of revoking capability: why does this improve the efficiency of the MDS?  
4. BLAH - need to diff the packages on issdm-36 and the rest... and look pthread libraries (sudo apt-get on ceph.com)?

End file
