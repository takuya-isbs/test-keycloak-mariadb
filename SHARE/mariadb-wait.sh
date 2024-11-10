#!/bin/sh
set -eu

while ! ./mariadb-status.sh 2>/dev/null | grep wsrep_local_state_comment | grep -q Synced; do
    echo "waiting for startup of mariadb"
    sleep 1
done

echo "mariadb is ready."
