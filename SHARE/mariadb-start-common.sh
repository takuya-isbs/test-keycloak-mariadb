#!/bin/bash
set -eu
set -x

./mariadb-stop.sh
./fluentd-start.sh

WSREP_NODE_ADDRESS=$(hostname) docker compose up -d --force-recreate --build mariadb

./mariadb-wait.sh
