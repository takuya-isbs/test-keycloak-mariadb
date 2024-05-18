#!/bin/bash

set -eu
set -x

CONTAINER=${1:-}

# TODO common.sh
IPADDR_PREFIX=10.60.204
PROJECT="testkc"

HOSTNAME=$(hostname)
HOST_SUFFIX=${HOSTNAME#"${PROJECT}-"}

case $HOST_SUFFIX in
    kc1)
	HOST_INDEX=101
	;;
    kc2)
	HOST_INDEX=102
	;;
    kc3)
	HOST_INDEX=103
	;;
    *)
	echo >&2 "Unknown host: ${HOSTNAME}"
	exit 1
	;;
esac

MY_IPADDR=${IPADDR_PREFIX}.${HOST_INDEX}

if [ -n "$CONTAINER" ]; then
    # recreate (a container) mode
    MY_IPADDR=$MY_IPADDR docker compose up -d --force-recreate "$CONTAINER"
else
    # up all
    MY_IPADDR=$MY_IPADDR docker compose up -d --no-recreate
fi
