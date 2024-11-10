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
    manage)
        HOST_INDEX=104
        ;;
    *)
        echo >&2 "Unknown host: ${HOSTNAME}"
        exit 1
        ;;
esac

MY_IPADDR=${IPADDR_PREFIX}.${HOST_INDEX}

COMPOSE() {
    MY_HOSTNAME=$HOSTNAME MY_IPADDR=$MY_IPADDR docker compose "$@"
}

if [ "$CONTAINER" = "INIT" ]; then
    COMPOSE up -d --no-recreate nginx keepalived keycloak
elif [ "$CONTAINER" = "ALL" ]; then
    COMPOSE up -d --no-recreate nginx keepalived keycloak jwt-server
elif [ "$CONTAINER" = "INIT-OLD" ]; then
    COMPOSE up -d --no-recreate nginx keepalived keycloak-old
elif [ "$CONTAINER" = "ALL-OLD" ]; then
    COMPOSE up -d --no-recreate nginx keepalived keycloak-old jwt-server
elif [ -n "$CONTAINER" ]; then
    # recreate (a container) mode
    COMPOSE up -d --force-recreate "$CONTAINER"
else
    echo "Usage: ./up.sh ALL|<CONTAINER_NAME>"
fi
