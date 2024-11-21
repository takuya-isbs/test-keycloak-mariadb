#!/bin/bash
set -eu
#set -x

COMPOSE="docker compose -f ./compose-manage.yml"

CONFIG_PY_URL=https://raw.githubusercontent.com/oss-tsukuba/gfarm/fe905dcaa2fd047a02a75c61065e99fc136b9cec/docker/dist/jwt-server/setup-keycloak/keycloak-config.py

if [ ! -f ./setup-keycloak/keycloak-config.py ]; then
    curl -o ./setup-keycloak/keycloak-config.py $CONFIG_PY_URL
fi
chmod a+r ./setup-keycloak/keycloak-config.py

#$COMPOSE run --remove-orphans --rm -it setup-keycloak /bin/bash

$COMPOSE run --remove-orphans --rm -it setup-keycloak \
       python3 /setup-keycloak/keycloak-config.py /setup-keycloak/keycloak-config.yaml
