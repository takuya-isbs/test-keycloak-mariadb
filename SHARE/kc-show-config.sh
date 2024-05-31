#!/bin/sh
set -eu
set -x

docker compose exec keycloak /opt/keycloak/bin/kc.sh show-config
