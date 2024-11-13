#!/bin/bash
set -eu
set -x

PROJECT=testkeycloak
DATADIR=/data/glusterfs
VOLNAME=log-volume

mkdir -p $DATADIR

gluster volume info $VOLNAME && exit 0

gluster peer probe ${PROJECT}-kc2
gluster peer probe ${PROJECT}-kc3

# force: use / partition
gluster volume create $VOLNAME replica 3 ${PROJECT}-kc1:${DATADIR}/brick1 ${PROJECT}-kc2:${DATADIR}/brick2 ${PROJECT}-kc3:${DATADIR}/brick3 force
gluster volume start $VOLNAME

#TODO
#gluster volume set $VOLNAME auth.allow 10.60.204.101,10.60.204.102,10.60.204.103
