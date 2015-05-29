echo deb http://ceph.com/packages/ceph-extras/debian $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph-extras.list

sudo apt-get install openmpi-bin libleveldb libpopt-dev binutils-dev -y

#packages from 'build ceph'
#http://ceph.com/docs/master/install/build-ceph/

#packages from 'installing oprofile'
#http://ceph.com/docs/master/dev/cpu-profiler/

#packages from 'installing documentation'
#https://ceph.com/docs/master/dev/generatedocs/

#packages from 'sudo make install opcontrol'
sudo apt-get install libpopt-dev libblkid-dev  -y
#ceph-mds-dbg

#dpkg: dependency problems prevent configuration of ceph-0.72.2:
# ceph-0.72.2 depends on libboost-program-options1.49.0 (>= 1.49.0-1); however:
#  Package libboost-program-options1.49.0 is not installed.
# ceph-0.72.2 depends on libboost-thread1.49.0 (>= 1.49.0-1); however:
#  Package libboost-thread1.49.0 is not installed.
# ceph-0.72.2 depends on libc6 (>= 2.16); however:
#  Version of libc6 on system is 2.15-0ubuntu10.5.
# ceph-0.72.2 depends on libgoogle-perftools4; however:
#  Package libgoogle-perftools4 is not installed.

#python-dbg

#ceph-deploy

#add upstart scripts to /etc/init/
sudo apt-get install lua5.2 liblua5.2-dev libfuse2 -y
sudo apt-get install python-software-properties -y
sudo apt-add-repository ppa:lttng/ppa -y
sudo apt-get update -y
sudo apt-get install lttng-tools -y
sudo apt-get install lttng-ust-dev -y
sudo apt-get install liblttng-ust-dev -y
sudo apt-get install build-essential libsqlite3-dev sqlite3 bzip2 libbz2-dev -y
# For babeltrace
sudo apt-get install bison flex swig -y
sudo apt-get install liblttng-ctl0 liblttng-ust0 -y
sudo apt-get install libleveldb1 -y
