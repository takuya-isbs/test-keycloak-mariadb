#!/bin/bash
set -eu
source ./common.sh

lxc network create $NETWORK_NAME
lxc network edit $NETWORK_NAME <<EOF
config:
  ipv4.address: 10.60.204.1/24
  ipv4.dhcp.ranges: 10.60.204.100-10.60.204.200
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

for HOST in $HOSTS; do
    lxc launch $LXD_IMAGE $HOST -p $PROFILE_NAME
done

lxc ls ${PROJECT}-
