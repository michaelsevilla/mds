#/bin/bash
sudo chown -R msevilla:msevilla /mnt/cephfs
mpirun --host localhost,localhost,localhost,localhost,localhost  ~/programs/mdtest/mdtest -F -C -n 100000 -d /mnt/cephfs/dir0
