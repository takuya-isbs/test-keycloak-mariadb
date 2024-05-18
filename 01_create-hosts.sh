#!/bin/bash
set -eu
source ./common.sh

lxc network create $NETWORK_NAME
lxc network edit $NETWORK_NAME <<EOF
config:
  ipv4.address: ${IPADDR_PREFIX}.1/24
  ipv4.dhcp.ranges: ${IPADDR_PREFIX}.200-${IPADDR_PREFIX}.250
  ipv4.nat: "true"
description: ""
type: bridge
EOF

lxc profile create $PROFILE_NAME
lxc profile edit $PROFILE_NAME <<EOF
config:
  security.nesting: true
  security.privileged: true
description: test Keycloak+MariaDB
devices:
  eth0:
    name: eth0
    network: $NETWORK_NAME
    type: nic
  root:
    path: /
    pool: default
    type: disk
  share:
    source: ${PWD}/SHARE
    path: /SHARE
    type: disk
EOF

INDEX_START=101

INDEX=${INDEX_START}
for HOST in $HOSTS; do
    lxc launch $LXD_IMAGE $HOST -p $PROFILE_NAME -d eth0,ipv4.address=${IPADDR_PREFIX}.${INDEX}
    INDEX=$((INDEX + 1))
done

sleep 5
lxc ls ${PROJECT}-
