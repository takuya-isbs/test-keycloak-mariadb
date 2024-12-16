#!/bin/bash

set -eu
set -x

CONTAINER=${1:-}

# TODO common.sh
IPADDR_PREFIX=10.60.204
PROJECT="testkeycloak"

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

CONTLIST_COMMON="nginx keepalived-eth0 keepalived-eth1"
CONTLIST_NEW_BASE="$CONTLIST_COMMON keycloak"
CONTLIST_NEW_ALL="$CONTLIST_NEW_BASE jwt-server"
CONTLIST_OLD_BASE="$CONTLIST_COMMON keycloak-old"
CONTLIST_OLD_ALL="$CONTLIST_OLD_BASE jwt-server"

if [ "$CONTAINER" = "INIT" ]; then
    COMPOSE up -d --force-recreate $CONTLIST_NEW_BASE
elif [ "$CONTAINER" = "ALL" ]; then
    COMPOSE up -d --force-recreate $CONTLIST_NEW_ALL
elif [ "$CONTAINER" = "INIT-OLD" ]; then
    COMPOSE up -d --force-recreate $CONTLIST_OLD_BASE
elif [ "$CONTAINER" = "ALL-OLD" ]; then
    COMPOSE up -d --force-recreate $CONTLIST_OLD_ALL
elif [ -n "$CONTAINER" ]; then
    COMPOSE up -d --force-recreate "$CONTAINER"
else
    echo "Usage: ./up.sh ALL|<CONTAINER_NAME>"
fi
