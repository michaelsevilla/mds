#!/bin/bash

WHOAMI=`cat /etc/hostname`
echo -n "0" > /tmp/balancer_state

sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_log true
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_need_min 0.98
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_split_size 10000
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_split_size 50000
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_cache_size 0
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set client_cache_size 0
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_cache_size 100000000
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set client_cache_size 100000000
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set ms_async_op_threads 0

sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds_migrator 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds_balancer 2
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs 10
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs_metaload 0.5
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs_depth 4

sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_lua 1

# no migration
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "if_false_then"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=0"


# spill half to neighbor
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "if_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "if_MDSs[whoami][\"load\"]-MDSs[whoami+1][\"load\"]>allmetaload/2_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/2"
###sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"metaload.all\"]"
###sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"
###--sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=RDState();WRState(Max(0,wait-1))\\nif_wait==\"0\"_and_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then\\nWRState(1)"

# spill half to partitioned cluster
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"metaload.all\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "t=((#MDSs-whoami+1)/2)+whoami\\nwhile_t~=whoami_and_MDSs[t][\"load\"]>0.01_do_t=t-1_end\\nif_MDSs[whoami][\"load\"]>.01_and_MDSs[t][\"load\"]<0.01_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=MDSs[whoami][\"load\"]/2"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"

## fill and spill
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=tonumber(RDState());go=0\\nif_MDSs[whoami][\"cpu\"]>48_then\\nif_wait>0_then_WRState(wait-1)_else_WRState(2);go=1;end\\nelse_WRState(2)_end\\nif_go==1_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/8"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=MDSs[whoami][\"load\"]/10"

# self healing
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"cpu\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "t=1_while_MDSs[t][\"load\"]>=0.48_and_t>=whoami_do_t=t+1 end\\nif_t<whoami_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=allmetaload/4"

