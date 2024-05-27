#!/bin/sh
set -eu
set -x

docker compose exec mariadb sh /mariadb-add-jwt-server.sh
