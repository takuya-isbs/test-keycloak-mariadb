#!/bin/bash
set -eu
source ./common.sh

KC_TYPE="${1:-new}"
BACKUP="${2:-}"

if [ "$KC_TYPE" = "new" ]; then
    UP_TARGET=ALL
else
    UP_TARGET=ALL-OLD
    KC_TYPE=old
fi

#TODO backup and restore

for h in $DB_HOSTS; do
    lxc_exec $h ./_down.sh
    lxc_exec $h ./ufw.sh delete
    lxc_exec $h ./ufw.sh
done

lxc_exec kc1 ./setup-glusterfs.sh
lxc_exec kc1 ./mariadb-new.sh
if [ -n "$BACKUP" ]; then
    if [[ "$BACKUP" == SHARE/* || "$BACKUP" == ./SHARE/* ]]; then
        BACKUP=${BACKUP#./}
        BACKUP=${BACKUP#SHARE/}
    fi
    lxc_exec kc1 ./mariadb-restore.sh "$BACKUP"
fi
lxc_exec kc1 ./mariadb-init-jwt-server.sh

lxc_exec kc2 ./mariadb-join.sh
lxc_exec kc3 ./mariadb-join.sh

lxc_exec kc1 ./up.sh $UP_TARGET
lxc_exec manage ./install-keycloak-api.sh
lxc_exec manage ./keycloak-config.sh
if [ "$KC_TYPE" = "new" ]; then
    # not for "old"
    lxc_exec kc1 ./keycloak-config-for-localhost.sh

    # re-update to set user attributes
    # TODO use ./keyclaok-add-user.sh instead of ./keycloak-config.sh
    lxc_exec manage ./keycloak-config.sh
fi

lxc_exec kc1 docker compose restart jwt-server
lxc_exec kc2 ./up.sh $UP_TARGET
lxc_exec kc3 ./up.sh $UP_TARGET

if [ "$KC_TYPE" = "old" ]; then
    lxc_exec kc1 ./mariadb-init-keycloak.sh
fi
while ! ./health-check.sh; do
    echo "retry health-check"
    sleep 2
done
