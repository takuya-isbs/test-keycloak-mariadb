#!/bin/bash
set -eu

docker compose exec mariadb /usr/local/bin/run-sysbench
