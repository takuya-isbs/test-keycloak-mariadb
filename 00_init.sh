#!/bin/bash

source ./common.sh

if [ -n "${HTTP_PROXY:-}" ]; then
    $LXC config set core.proxy_http ${HTTP_PROXY}
fi
if [ -n "${HTTPS_PROXY:-}" ]; then
    $LXC config set core.proxy_https ${HTTPS_PROXY}
fi
if [ -n "${NO_PROXY:-}" ]; then
    $LXC config set core.proxy_ignore_hosts ${NO_PROXY}
fi
$LXC config show
