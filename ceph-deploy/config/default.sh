max mds = 20
osd_pool_default_size = 1
#client cache size = 1215752192
#client cache size = 16384000
#client cache size = 100000000
client cache size = 0

[osd]
debug osd = 0
#log file = /mnt/vol2/msevilla/ceph-logs/osd/$name.log
osd op threads = 4
filestore_max_sync_interval = 20
#osd_objectstore = keyvaluestore-dev
#keyvaluestore_backend = rocksdb

[mon]
debug mon = 1
log file = /mnt/vol2/msevilla/ceph-logs/mon/$name.log

[mds]
debug ms = 0
debug mds = 0
log file = /mnt/vol2/msevilla/ceph-logs/mds/$name.log
mds log = true
#ms_async_op_threads = 0
mds bal max until = -1
mds bal mode = 2
#mds bal frag = true
#mds bal split size = 2000
#mds cache size = 100000000
mds cache size = 0
mds log max expiring = 40
mds log max segments = 120

[client]
debug client = 0
