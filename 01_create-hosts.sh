#!/bin/bash
set -eu
source ./common.sh

$LXC network create $NETWORK_NAME || true

MAC=$(ip a show $NETWORK_NAME | awk '/link\/ether/ {print $2}')
IPV6=$(./ula_generator.py ${MAC} | grep "First IPv6 Address" | awk '{print $4}')

$LXC  network edit $NETWORK_NAME <<EOF
config:
  ipv4.address: ${IPADDR_PREFIX}.1/24
  ipv4.dhcp.ranges: ${IPADDR_PREFIX}.200-${IPADDR_PREFIX}.250
  ipv4.nat: "true"
  ipv6.address: ${IPV6}
  ipv6.dhcp: "true"
  ipv6.nat: "true"
description: ""
type: bridge
EOF

$LXC profile create $PROFILE_NAME || true
$LXC profile edit $PROFILE_NAME <<EOF
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
    pool: ${LXD_POOL}
    type: disk
    size: 40GB
  share:
    source: ${PWD}/SHARE
    path: /SHARE
    type: disk
EOF

INDEX_START=101

INDEX=${INDEX_START}
for HOST in $HOSTS; do
    FULLNAME=${PROJECT}-${HOST}
    if lxc_exist $FULLNAME; then
	echo "exist: ${FULLNAME}"
    else
	$LXC launch $LXD_IMAGE ${FULLNAME} -p $PROFILE_NAME -d eth0,ipv4.address=${IPADDR_PREFIX}.${INDEX}
    fi
    INDEX=$((INDEX + 1))
done

sleep 5
$LXC ls ${PROJECT}-
