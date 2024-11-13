#!/bin/bash
set -eu
source ./common.sh

#TODO backup and restore

lxc_exec kc1 ./_down.sh
lxc_exec kc2 ./_down.sh
lxc_exec kc3 ./_down.sh

lxc_exec kc1 ./setup-glusterfs.sh
lxc_exec kc1 ./mariadb-new.sh
lxc_exec kc2 ./mariadb-join.sh
lxc_exec kc3 ./mariadb-join.sh

lxc_exec kc1 ./mariadb-init-jwt-server.sh
lxc_exec kc1 ./up.sh INIT
lxc_exec manage ./install-keycloak-api.sh
lxc_exec manage ./keycloak-config.sh
lxc_exec kc1 ./keycloak-config-for-localhost.sh
# re-update to set user attributes
lxc_exec manage ./keycloak-config.sh
lxc_exec kc1 ./up.sh jwt-server
lxc_exec kc2 ./up.sh jwt-server
lxc_exec kc3 ./up.sh jwt-server
