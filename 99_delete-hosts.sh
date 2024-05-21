#!/bin/bash

source ./common.sh

for HOST in $HOSTS; do
    lxc delete -f ${PROJECT}-${HOST} || true
done

lxc profile delete $PROFILE_NAME || true
lxc network delete $NETWORK_NAME || true
