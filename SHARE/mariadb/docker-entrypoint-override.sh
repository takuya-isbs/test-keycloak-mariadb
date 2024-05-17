#!/bin/bash

set -eu
set -x

# SEE ALSO: https://github.com/MariaDB/mariadb-docker/blob/d7a950d41e9347ac94ad2d2f28469bff74858db7/10.6/docker-entrypoint.sh

WSREP_NEW_CLUSTER=${WSREP_NEW_CLUSTER:-no}

if [ $WSREP_NEW_CLUSTER = "yes" ]; then
    set -- "$@" --wsrep-new-cluster
fi

hosts=""
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[ \t]*//; s/[ \t]*$//')
    if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
        continue
    fi
    if [ -z "$hosts" ]; then
        hosts="$line"
    else
        hosts="$hosts,$line"
    fi
done < /hostlist.txt

WSREP_CLUSTER_ADDRESS="gcomm://${hosts}"

IST_RECV_ADDR=${WSREP_NODE_ADDRESS}  # external address
IST_BIND_ADDR=0.0.0.0
set -- "$@" "--wsrep-provider-options=ist.recv_addr=${IST_RECV_ADDR};ist.recv_bind=${IST_BIND_ADDR}"

sed -e "s;@wsrep_node_address@;${WSREP_NODE_ADDRESS};g" \
    -e "s;@wsrep_cluster_address@;${WSREP_CLUSTER_ADDRESS};g" \
    /galera.cnf.tmpl > /etc/mysql/conf.d/galera.cnf

# log for debug
ls -la /var/lib/mysql/

exec "$@"
