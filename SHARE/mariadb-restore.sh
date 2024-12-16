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

#if [[ $BACKUP_FILE =~ backup-mariadb-([^-]+)-[0-9]{8}-[0-9]{4}\.gz ]]; then
if [[ $BACKUP_FILE =~ backup-mariadb-(keycloak|jwtserver)-[0-9]{8}-[0-9]{4}\.gz ]]; then
    DBNAME="${BASH_REMATCH[1]}"
elif [[ $BACKUP_FILE =~ backup-mariadb-ALL-[0-9]{8}-[0-9]{4}\.gz ]]; then
    DBNAME=""
else
    echo "unexpected backup file: $BACKUP_FILE"
    exit 1
fi

COMPOSE="docker compose exec -T mariadb"

zcat "$BACKUP_FILE" | $COMPOSE sh -c "mariadb -uroot $DBNAME"
$COMPOSE sh -c 'mariadb -uroot -e "FLUSH PRIVILEGES"'
