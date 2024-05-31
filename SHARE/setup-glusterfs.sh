#!/bin/bash
set -eu
set -x

DATADIR=/data/glusterfs

mkdir -p $DATADIR

gluster peer probe testkc-kc2
gluster peer probe testkc-kc3

# force: use / partition
gluster volume create log-volume replica 3 testkc-kc1:${DATADIR}/brick1 testkc-kc2:${DATADIR}/brick2 testkc-kc3:${DATADIR}/brick3 force
gluster volume start log-volume

#gluster volume set log-volume auth.allow 10.60.204.101,10.60.204.102,10.60.204.103
