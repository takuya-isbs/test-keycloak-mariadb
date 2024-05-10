#!/bin/bash
set -eu
set -x

USER=sysbenchuser
PASS=sysbenchpass
DB=sysbenchtest

COUNT=$(mariadb --silent --skip-column-names -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${DB}';")

SYSBENCH="sysbench /usr/share/sysbench/oltp_read_write.lua"

if [ $COUNT -ne 1 ]; then
  mariadb -e "create database ${DB};"
  mariadb -e "GRANT ALL ON sysbenchtest.* TO '${USER}'@'127.0.0.1' IDENTIFIED BY '${PASS}';"
  $SYSBENCH \
      --db-driver=mysql \
      --table-size=1000000 \
      --mysql-host=127.0.0.1 \
      --mysql-db=${DB} \
      --mysql-user=${USER} \
      --mysql-password=${PASS} \
      --time=60 \
      --db-ps-mode=disable prepare
fi

$SYSBENCH \
    --db-driver=mysql \
    --table-size=100000 \
    --mysql-host=127.0.0.1 \
    --mysql-db=${DB} \
    --mysql-user=${USER} \
    --mysql-password=${PASS} \
    --time=60 \
    --db-ps-mode=disable \
    --threads=8 run
