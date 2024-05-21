#!/bin/bash
set -eu
source ./common.sh

# for HOST in $HOSTS; do
#     lxc exec $HOST sh /SHARE/install-docker.sh
# done

exec_para "$HOSTS" sh /SHARE/install-docker.sh
