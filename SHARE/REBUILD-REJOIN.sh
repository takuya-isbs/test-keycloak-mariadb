#!/bin/bash
set -eu
set -x

docker compose down -v
docker compose build
./fluentd-start.sh
./mariadb-join.sh

while :; do
    status=$(docker compose exec mariadb mariadb-admin ping | grep "is alive" | wc -l || true)
    if [ "$status" = "1" ]; then
        break
    fi
    sleep 1
done

./up.sh ALL
