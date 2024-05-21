#!/bin/bash
set -eu
set -x

WSREP_NEW_CLUSTER=no WSREP_NODE_ADDRESS=$(hostname) docker compose up -d --no-recreate mariadb
