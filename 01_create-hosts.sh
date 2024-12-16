#!/bin/bash
set -eu
source ./common.sh

$LXC network create $NETWORK0_NAME || true
$LXC network create $NETWORK1_NAME || true

MAC=$(ip a show $NETWORK0_NAME | awk '/link\/ether/ {print $2}')
IPV6=$(./ula_generator.py ${MAC} | grep "First IPv6 Address" | awk '{print $4}')

$LXC  network edit $NETWORK0_NAME <<EOF
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

$LXC  network edit $NETWORK1_NAME <<EOF
config:
  ipv4.address: "none"
  ipv4.nat: "false"
  ipv6.address: "none"
  ipv6.dhcp: "false"
  ipv6.nat: "false"
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
    network: $NETWORK0_NAME
    type: nic
  eth1:
    name: eth1
    network: $NETWORK1_NAME
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

config_eth1_netplan() {
    local NAME="$1"
    local IPADDR="$2"
    local CONF=/etc/netplan/60-eth1.yaml
    $LXC exec "$NAME" -- tee $CONF <<EOF
network:
  version: 2
  ethernets:
    eth1:
      addresses:
         - ${IPADDR}/24
      dhcp4: false
      dhcp6: false
      accept-ra: false
      link-local: []
EOF
}

INDEX_START=101

INDEX=${INDEX_START}
for HOST in $HOSTS; do
    FULLNAME=${PROJECT}-${HOST}
    if lxc_exist $FULLNAME; then
	echo "exist: ${FULLNAME}"
    else
	$LXC launch $LXD_IMAGE ${FULLNAME} -p $PROFILE_NAME -d eth0,ipv4.address=${IPADDR_PREFIX}.${INDEX}
	config_eth1_netplan ${FULLNAME} ${IPADDR_PREFIX1}.${INDEX}
    fi
    INDEX=$((INDEX + 1))
done

sleep 5
$LXC ls ${PROJECT}-
