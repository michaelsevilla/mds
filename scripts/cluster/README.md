These scripts are used to deploy, stop, and reset Ceph clusters.
- cleanup.sh: delete Ceph processes and unmount client
- collect.sh: get stats every x seconds (uses collectl, oprofile, and Ceph perf counters)
- config.sh: defines Ceph cluster setup
- README.md: this file
- reset.sh: stops all Ceph processes and deletes leftover directories
- start.sh: starts the Ceph cluster (runs ceph-deploy)
- stop.sh: stops collect.sh daemons and moves log to piha

