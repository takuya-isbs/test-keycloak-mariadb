#!/bin/bash

cp_backup_restore() {
    local FILE="$1"
    local ORIG="${FILE}.orig"
    if [ -f "$ORIG" ]; then
        cp -f "$ORIG" "$FILE"
    else
        cp "$FILE" "$ORIG"
    fi
}

#TODO generate .env
COMPOSE_PROJECT_NAME=kc

docker_cont_ipaddr() {
    local NAME="$1"
    local FULLNAME="${COMPOSE_PROJECT_NAME}-${NAME}-1"
    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $FULLNAME
}

docker_cont_ports() {
    local NAME="$1"
    local FULLNAME="${COMPOSE_PROJECT_NAME}-${NAME}-1"
    docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{with $conf}}{{$p}}{{"\n"}}{{end}}{{end}}' $FULLNAME
}

read_listfile() {
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[ \t]*//; s/[ \t]*$//')
        if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
            continue
        fi
        echo "$line"
    done < "$1"
}

myip() {
    ./myip.sh
}

is_a_node() {
    found=false
    for myip in $(myip); do
        for ip in $(read_listfile ./ipaddr-list.txt); do
            if [ "$myip" = "$ip" ]; then
               found=true
               break
            fi
        done
    done
    $found
}

if ! is_a_node; then
    echo >&2 "Error: $0 can be used for the nodes in ipaddr-list.txt"
    exit 1
fi
