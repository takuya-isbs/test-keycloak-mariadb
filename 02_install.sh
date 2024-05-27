#!/bin/bash
set -eu
source ./common.sh

CONF=./SHARE/_config.sh

cat <<EOF > $CONF
DOCKER_USER=$DOCKER_USER
DOCKER_PASS=$DOCKER_PASS
EOF

exec_para "$HOSTS" sh /SHARE/install-docker.sh

$LXC exec "$HOST_MANAGE" bash /SHARE/setup-manage.sh

# SEE: https://matsuand.github.io/docs.docker.jp.onthefly/config/daemon/systemd/
# ARGS: registry-mirrors
for HOST in $DB_HOSTS; do
    FULLNAME=${PROJECT}-${HOST}
    $LXC exec $FULLNAME bash /SHARE/setup-proxy.sh "${HTTP_PROXY:-}" "${HTTPS_PROXY:-}" "${NO_PROXY:-}" "${DOCKER_REGISTRY_PROXY:-}"
done
