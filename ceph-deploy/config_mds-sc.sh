#!/bin/bash

WHOAMI=`cat /etc/hostname`
echo -n "2" > /tmp/balancer_state
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set debug_mds_balancer 15

sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "
x=4\\n\
if_false_then\\n\
  x=3\\n\
end\\n\
if_false_then"
exit

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
# spill half to neighbor
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "if_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=tonumber(RDState());go=0\\nt=whoami+1\\nif_t>#MDSs_then_t=1_end\\ntload=(MDSs[whoami][\"load\"]+MDSs[t][\"load\"])/2\\nif_MDSs[whoami][\"load\"]>tload_then\\nif_wait>0_then_WRState(wait-1)_else_WRState(2);go=1;end\\nelse_WRState(2)_end\\nif_go==1_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/2"
###sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"
###--sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=RDState();WRState(Max(0,wait-1))\\nif_wait==\"0\"_and_MDSs[whoami][\"load\"]>.01_and_MDSs[whoami+1][\"load\"]<0.01_then\\nWRState(1)"

# spill half to partitioned cluster
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "t=((#MDSs-whoami+1)/2)+whoami\\nif_t>#MDSs_then_t=whoami_end\\nwhile_t~=whoami_and_MDSs[t][\"load\"]>0.01_do_t=t-1_end\\nif_MDSs[whoami][\"load\"]>0.01_and_MDSs[t][\"load\"]<0.01_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=MDSs[whoami][\"load\"]/2"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\"}"

## fill and spill
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=tonumber(RDState());go=0\\nif_MDSs[whoami][\"cpu\"]>48_then\\nif_wait>0_then_WRState(wait-1)_else_WRState(2);go=1;end\\nelse_WRState(2)_end\\nif_go==1_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=allmetaload/8"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[whoami+1]=MDSs[whoami][\"load\"]/10"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "wait=tonumber(RDState());go=0\\nt=whoami+1\\nif_t>#MDSs_then_t=1_end\\ntload=(MDSs[whoami][\"load\"]+MDSs[t][\"load\"])/2\\nif_MDSs[whoami][\"load\"]>tload_then\\nif_wait>0_then_WRState(wait-1)_else_WRState(2);go=1;end\\nelse_WRState(2)_end\\nif_go==1_then"
##sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "targets[t]=MDSs[whoami][\"load\"]-tload"

####
# self healing (good for compile AND sepdir)
####
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_minoffload 2
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_metaload "IWR"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_mdsload "MDSs[i][\"all\"]"
## wait 3
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "go=1;tLoad=total/#MDSs\\nmyLoad=tonumber(MDSs[whoami][\"load\"])\\nfor_i=1,#MDSs_do\\ntheirLoad=tonumber(MDSs[i][\"load\"])\\nif_myLoad<theirLoad_then_go=0;io.write(string.format(\"not_migrating_myLoad=%d,theirLoad=%d_\",myLoad,theirLoad));_end\\nend\\nwait=tonumber(RDState())\\nif_go==1_then\\nif_wait>0_then_WRState(wait-1);go=0_else_WRState(2)_end\\nelse_WRState(2)_end\\nif_go==1_and_myLoad>tLoad_then"
# WHEN (aggressive)
# go=1
# tLoad=total/#MDSs
# myLoad=tonumber(MDSs[whoami][\"load\"])
# for_i=1,#MDSs do
#   theirLoad=tonumber(MDSs[i][\"load\"])
#   if myLoad<theirLoad then 
#     go=0 
#     io.write(string.format(\"not_migrating_myLoad=%d,theirLoad=%d_\",myLoad,theirLoad));
#   end
# end
# if_go==1 and myLoad>total/2 then
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "go=1;tLoad=total/#MDSs\\nmyLoad=tonumber(MDSs[whoami][\"load\"])\\nfor_i=1,#MDSs_do\\ntheirLoad=tonumber(MDSs[i][\"load\"])\\nif_myLoad<theirLoad_then_go=0;io.write(string.format(\"not_migrating_myLoad=%d,theirLoad=%d_\",myLoad,theirLoad));_end\\nend\\nif_go==1_and_myLoad>total/2_then"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "for_i=1,#MDSs_do\\ntheirLoad=tonumber(MDSs[i][\"load\"])\\nif_theirLoad<tLoad_then_targets[i]=tLoad-theirLoad_end_end"
## conservative
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "max=0\\nfor_i=1,#MDSs_do\\nif_MDSs[i][\"load\"]>max_then_max=MDSs[i][\"load\"]_end_end\\nmyLoad=MDSs[whoami][\"load\"]\\nio.write(string.format(\"myLoad=%d,max=%d,total=%d\",myLoad,max,total))\\nif_myLoad>total/2_and_myLoad>=max_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_when "myLoad=MDSs[whoami][\"load\"]\\nif_myLoad>total/#MDSs_then"
#sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_where "tLoad=total/#MDSs\\nfor_i=1,#MDSs_do\\ntheirLoad=MDSs[i][\"load\"]\\nif_theirLoad<tLoad_then_targets[i]=tLoad-theirLoad_end_end"
sudo ceph --admin-daemon /var/run/ceph/ceph-mds.$WHOAMI.asok config set mds_bal_howmuch "{\"half\", \"small_first\", \"small_first_plus1\", \"big_first\", \"big_first_plus1\", \"big_half\", \"small_half\"}"
#
