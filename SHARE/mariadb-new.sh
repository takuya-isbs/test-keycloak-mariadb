#!/bin/bash
set -eu
set -x

WSREP_NEW_CLUSTER=yes WSREP_NODE_ADDRESS=$(hostname) docker compose up -d mariadb
