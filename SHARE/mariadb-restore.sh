#!/bin/bash
set -eu
set -x

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    cat <<EOF >&2
${BACKUP_FILE}: No such file
EOF
    exit 1
fi

COMPOSE="docker compose exec -T mariadb"

zcat "$BACKUP_FILE" | $COMPOSE sh -c 'mariadb -uroot'
$COMPOSE sh -c 'mariadb -uroot -e "FLUSH PRIVILEGES"'
