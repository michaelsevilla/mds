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
4. Figure out where MDS error warnings are going...  
5. Make sure that client leases are getting revoked...  why are tehy only getting revoked on 1 mds?  
6. re-run and try to migrate before leases expire  
7. define states of MDS and which we want to avoid (difference between trimming, flushing, and expiring.  
8. Why would trimming cause revoke of capability?
9. Add debugging of states.
10. Does inside number coincide with lookups? Show we have two different events.  
11. Why can't pthread grab the lock? It is not because of memory pressure... is it random??

End file
