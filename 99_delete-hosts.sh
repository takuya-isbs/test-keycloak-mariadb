#!/bin/bash

source ./common.sh

ALL="${1:-}"

if [ "$ALL" = all ]; then
    TARGETS=$HOSTS
else
    TARGETS=$DB_HOSTS
fi

for HOST in $TARGETS; do
    lxc delete -f ${PROJECT}-${HOST} || true
done

lxc profile delete $PROFILE_NAME || true
lxc network delete $NETWORK0_NAME || true  # may fail
lxc network delete $NETWORK1_NAME || true  # may fail
