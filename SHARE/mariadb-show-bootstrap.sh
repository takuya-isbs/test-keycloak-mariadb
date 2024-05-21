#!/bin/bash
set -eu
#set -x

docker compose run -it --rm --entrypoint cat mariadb /var/lib/mysql/grastate.dat | grep '^safe_to_bootstrap:'
