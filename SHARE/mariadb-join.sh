#!/bin/bash
set -eu
set -x

./mariadb-stop.sh
./fluentd-start.sh

WSREP_NEW_CLUSTER=no WSREP_NODE_ADDRESS=$(hostname) docker compose up -d --force-recreate mariadb

./mariadb-wait.sh
