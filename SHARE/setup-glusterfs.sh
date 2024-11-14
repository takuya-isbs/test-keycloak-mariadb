#!/bin/bash
set -eu
set -x

PROJECT=testkeycloak
DATADIR=/data/glusterfs
VOLNAME=log-volume

mkdir -p $DATADIR

gluster peer probe ${PROJECT}-kc2
gluster peer probe ${PROJECT}-kc3
NUM_PEER=2

while :; do
    count=$(gluster peer status | grep "State: Peer in Cluster (Connected)" | wc -l)
    if [ $count -eq $NUM_PEER ]; then
	break
    fi
    sleep 1
    echo -n "."
done
echo

# force: use / partition
gluster volume create $VOLNAME replica 3 ${PROJECT}-kc1:${DATADIR}/brick1 ${PROJECT}-kc2:${DATADIR}/brick2 ${PROJECT}-kc3:${DATADIR}/brick3 force || :
gluster volume start $VOLNAME || :

#TODO
#gluster volume set $VOLNAME auth.allow 10.60.204.101,10.60.204.102,10.60.204.103


# MEMO: how to detach
# gluster volume remove-brick log-volume replica 2 testkeycloak-kc3:/data/glusterfs/brick3 force
# gluster peer detach testkeycloak-kc3
