#!/bin/bash
set -eu
source ./common.sh
set +x

get_ipaddrs() {
    local NAME="$1"
    lxc list -f json | jq -r '.[] | select(.name == "'"$NAME"'") | .state.network.eth0.addresses[] | select(.family == "inet") | .address'
}

while :; do
    echo "### ctrl-c to stop ###"
    FOUND=
    for HOST in $DB_HOSTS; do
        FULLNAME=${PROJECT}-${HOST}
        ipaddrs=$(get_ipaddrs $FULLNAME)
        for ipaddr in $ipaddrs; do
            if [ "$ipaddr" = "$VIP" ]; then
                FOUND=$FULLNAME
                break
            fi
        done
        if [ -n "$FOUND" ]; then
            break
        fi
    done
    if [ -z "$FOUND" ]; then
        echo >&2 "$VIP: not found"
        exit 1
    fi
    echo "restart keepalived: $FOUND"
    $LXC exec --cwd /SHARE $FOUND docker compose restart keepalived
    sleep 1
    lxc ls ${PROJECT}-kc
    sleep 10
done
