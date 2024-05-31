#!/bin/bash
set -eu
set -x

umount /mnt/glusterfs || true
mkdir -p /mnt/glusterfs
mount -t glusterfs $(hostname):/log-volume /mnt/glusterfs
