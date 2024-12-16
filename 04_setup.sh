#!/bin/bash
set -eu
source ./common.sh

OLD="${1:-}"

if [ "$OLD" = "old" ]; then
    INIT_TARGET=INIT-OLD
    UP_TARGET=ALL-OLD
else
    INIT_TARGET=INIT
    UP_TARGET=ALL
fi

#TODO backup and restore

lxc_exec kc1 ./_down.sh
lxc_exec kc2 ./_down.sh
lxc_exec kc3 ./_down.sh

lxc_exec kc1 ./setup-glusterfs.sh
lxc_exec kc1 ./mariadb-new.sh
lxc_exec kc2 ./mariadb-join.sh
lxc_exec kc3 ./mariadb-join.sh

lxc_exec kc1 ./mariadb-init-jwt-server.sh
lxc_exec kc1 ./up.sh $INIT_TARGET
lxc_exec manage ./install-keycloak-api.sh
lxc_exec manage ./keycloak-config.sh
if [ "$INIT_TARGET" = "INIT" ]; then
    # not for INIT-OLD
    lxc_exec kc1 ./keycloak-config-for-localhost.sh
fi
# re-update to set user attributes
# TODO use ./keyclaok-add-user.sh instead of ./keycloak-config.sh
lxc_exec manage ./keycloak-config.sh

lxc_exec kc1 ./up.sh jwt-server
lxc_exec kc2 ./up.sh $UP_TARGET
lxc_exec kc3 ./up.sh $UP_TARGET
