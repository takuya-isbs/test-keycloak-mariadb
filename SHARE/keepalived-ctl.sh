#!/bin/sh
OP="$1"
docker compose $OP keepalived-eth0 keepalived-eth1
