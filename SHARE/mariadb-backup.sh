#!/bin/bash
set -eu
set -x
shopt -s extglob

DBNAME="${1:-}"
PATT="keycloak|jwtserver|ALL"

case $DBNAME in
    @($PATT))
	echo "DBNAME=$DBNAME"
	;;
    *)
	echo "unexpected DBNAME=$DBNAME (expect $PATT)"
	exit 1
	;;
esac

# REF.: https://mariadb.com/kb/en/container-backup-and-restoration/
mkdir -p BACKUP
DT=$(date +%Y%m%d-%H%M)
FILE=./BACKUP/backup-mariadb-${DBNAME}-${DT}.gz

COMPOSE="docker compose exec -T mariadb"
DUMP="$COMPOSE mariadb-dump --single-transaction -uroot"

if [ $DBNAME = ALL ]; then
    $DUMP --all-databases | gzip > $FILE
else
    $DUMP $DBNAME | gzip > $FILE
fi

echo "DONE: $FILE"
