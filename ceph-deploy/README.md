-- Directions --
- To customize the Ceph cluster edit the config file:
    vim ./config.sh
- To start the Ceph cluster, run:
    ./start.sh
- To collect all the logs and kill logging processes, run:
    ./stop.sh
- To tear down the cluster, including all the Ceph processes, run:
    ./reset.sh

-- Log Files --
MDS
    ceph.mds-mds#.log
    ->  time    load    cpu-load
    perf counter dump
    ->  time    hits    misses  r-sum   r-cnt
    collectl
    ->  time    cpu


-- Commands --
sudo ceph mds tell 0 injectargs '--mds_lua_balancer /dir1:/tmp/nobalancer.lua,/:/tmp/balancer.lua'; sudo ceph mds tell 1 injectargs '--mds_lua_balancer /dir1:/tmp/nobalancer.lua,/:/tmp/balancer.lua'; sudo ceph mds tell 2 injectargs '--mds_lua_balancer /dir1:/tmp/nobalancer.lua,/:/tmp/balancer.lua';


./mdtest -F -C -n 100000 -d /mnt/cephfs/client1v4

for i in 3 0 21 34 39 40 46 15 41 5 11 44; do ssh issdm-$i "sudo dpkg --install ceph-orig_0_amd64.deb"; done

