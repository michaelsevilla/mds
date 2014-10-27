pid=`ps ax | grep ceph-fuse | grep -v grep | awk '{print $1}'`
echo "killing pid=$pid"
kill -9 $pid

mnt="/mnt/cephfs"
echo "unmounting $mnt"
umount $mnt

