#!/bin/bash
set -eu
set -x

LOGDIR=/mnt/glusterfs/fluentd-$(hostname)

# for alpine
#U=100
#G=101

# for debian
U=999
G=999

bash ./mount-glusterfs.sh

mkdir -p $LOGDIR
chown -R $U:$G $LOGDIR
chmod -R ug+X,o-rwx $LOGDIR
#chmod -R 777 $LOGDIR

./up.sh fluentd
