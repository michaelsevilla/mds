#!/bin/bash

WHOAMI=`cat /etc/hostname`
echo -n "2" > /tmp/balancer_state

# Debugging
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds_migrator 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds_balancer 2
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs 10
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs_metaload 0.5
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_print_dfs_depth 4

# Configuration parameters (i.e. tunables)
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_lua 1
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_log true
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_need_min 0.98
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_split_size 50000
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set ms_async_op_threads 0

##########
# Greedy Spill
##########
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_frag 1
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_cache_size 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set client_cache_size 0
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
##### spill half to neighbor
## migrate immediately
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "\
# if_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then"
## must be overloaded for 3 straight iterations
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "\
# wait=RDState();go=0 \
# t=whoami+1 \
# if_t>#MDSs_then_t=1_end \
#   tload=(MDSs[whoami][\"load\"]+MDSs[t][\"load\"])/2 \
#   if_MDSs[whoami][\"load\"]>tload_then\\nif_wait>0_then \
#     WRState(wait-1) \
#   else \
#     WRState(2) \
#     go=1 \
#   end \
# else \
#   WRState(2) \
# end \
# if_go==1_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/2"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"
###--sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=RDState();WRState(Max(0,wait-1))\\nif_wait==\"0\"_and_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then\\nWRState(1)"
##### spill evenly to partitioned cluster
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "\
t=((#MDSs-whoami+1)/2)+whoami \
if_t>#MDSs_then_t=whoami_end \
while_t~=whoami_and_MDSs[t][\"load\"]>0.01_do \
  t=t-1 \
end \
if_MDSs[whoami][\"load\"]>0.01_and_MDSs[t][\"load\"]<0.01_then"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=MDSs[whoami][\"load\"]/2"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"

##########
# Fill and Spill
##########
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when " \
#wait=tonumber(RDState());go=0 \
#if_MDSs[whoami][\"cpu\"]>48_then \
#  if_wait>0_then_WRState(wait-1) \
#  else_WRState(2);go=1;end \
#else_WRState(2)_end \
#if_go==1_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/8"
##### Spill 10%
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=MDSs[whoami][\"load\"]/10"
##### ????
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=tonumber(RDState());go=0\\nt=whoami+1\\nif_t>#MDSs_then_t=1_end\\ntload=(MDSs[whoami][\"load\"]+MDSs[t][\"load\"])/2\\nif_MDSs[whoami][\"load\"]>tload_then\\nif_wait>0_then_WRState(wait-1)_else_WRState(2);go=1;end\\nelse_WRState(2)_end\\nif_go==1_then"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=MDSs[whoami][\"load\"]-tload"

##########
# Self Healing (good for compile AND sepdir)
##########
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_cache_size 100000000
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set client_cache_size 100000000
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_minoffload 2
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"

##### conservative: must be overloaded for 3 straight iterations
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "\
# go=1;tLoad=total/#MDSs \
# myLoad=MDSs[whoami][\"load\"] \
# for_i=1,#MDSs_do \
#   theirLoad=MDSs[i][\"load\"] \
#   if_myLoad<theirLoad_then_ \
#     go=0;io.write(string.format(\"not_migrating_myLoad=%d,theirLoad=%d_\",myLoad,theirLoad)) \
#   end \
# end \
# wait=tonumber(RDState()) \
# if_go==1_then \
#   if_wait>0_then_WRState(wait-1);go=0 \
#   else_WRState(2) \
#   end \
# else_WRState(2)_end\\nif_go==1_and_myLoad>tLoad_then"

##### aggressive: set a low minimum load unit and migrate at the first sight of load
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "\
#go=1;tLoad=total/#MDSs \
#myLoad=tonumber(MDSs[whoami][\"load\"]) \
#for_i=1,#MDSs_do \
#  theirLoad=tonumber(MDSs[i][\"load\"]) \
#  if_myLoad<theirLoad_then_go=0 \
#    io.write(string.format(\"not_migrating_myLoad=%d,theirLoad=%d_\",myLoad,theirLoad)) \
#  end \
#end \
#if_go==1_and_myLoad>total/2_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "\
#for_i=1,#MDSs_do \
#  theirLoad=MDSs[i][\"load\"] \
#  if_theirLoad<tLoad_then \
#    targets[i]=tLoad-theirLoad \
#  end \
#end"

##### conservative
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when " \
max=0 \
for_i=1,#MDSs_do \
  max=Max(MDSs[i][\"load\", max) \
  myLoad=MDSs[whoami][\"load\"] \
end \
if_myLoad>total/2_and_myLoad>=max_then"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where " \
tLoad=total/#MDSs \
for_i=1,#MDSs_do \
  if_MDSs[i][\"load\"]<tLoad_then \
    targets[i]=tLoad-MDSs[i][\"load\"] \
  end \
end"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\", \"small_first\", \"small_first_plus1\", \"big_first\", \"big_first_plus1\", \"big_half\", \"small_half\"}"
