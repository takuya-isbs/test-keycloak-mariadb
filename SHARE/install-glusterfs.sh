#!/bin/bash
set -eu
set -x

apt-get update
apt-get install -y glusterfs-server
systemctl start glusterd
systemctl enable glusterd

DATADIR=/data/glusterfs
mkdir -p $DATADIR
