#!/bin/bash

source ./common.sh

for HOST in $HOSTS; do
    lxc delete -f $HOST || true
done

lxc profile delete $PROFILE_NAME || true
lxc network delete $NETWORK_NAME || true
