#!/bin/sh
set -eu
set -x

basedir=$(dirname $0)
cd $basedir

EXEC="docker compose exec mariadb"

#$EXEC mariadb -u root -e "show status like 'wsrep_cluster_%'"
$EXEC mariadb -u root -e "show status like 'wsrep_local_state_%'"
#$EXEC mariadb -u root -e "show status like 'wsrep_local_%'"
echo $?

#$EXEC mariadb -u root -e "select user,host from user" mysql
