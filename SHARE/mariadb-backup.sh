#!/bin/bash
set -eu
set -x

# REF.: https://mariadb.com/kb/en/container-backup-and-restoration/
mkdir -p BACKUP
DT=$(date +%Y%m%d-%H%M)
FILE=./BACKUP/backup-mariadb-${DT}.gz

docker compose exec mariadb \
       mariadb-dump --single-transaction --all-databases -uroot \
    | gzip > $FILE

echo "DONE: $FILE"
