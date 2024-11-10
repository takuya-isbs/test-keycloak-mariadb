#!/bin/sh
set -eu
set -x

docker compose exec mariadb sh /mariadb-unlimit-keycloak-USER_ATTRIBUTE.sh
