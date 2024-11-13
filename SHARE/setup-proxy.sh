#!/bin/bash

set -eu
set -x

PROJECT="testkeycloak"
NO_PROXY_DEFAULT="localhost,127.0.0.1,${PROJECT}-manage"
DOCKER_REGISTRY_PROXY_DEFAULT="http://${PROJECT}-manage:50000,http://${PROJECT}-manage:50001"

HTTP_PROXY="$1"
HTTPS_PROXY="$2"
NO_PROXY="$3"
DOCKER_REGISTRY_PROXY="${4:-${DOCKER_REGISTRY_PROXY_DEFAULT}}"


setup_http_proxy_for_docker() {
    SYSTEMD_DOCKER_DIR="/etc/systemd/system/docker.service.d"
    SYSTEMD_DOCKER_PROXY="${SYSTEMD_DOCKER_DIR}/http-proxy.conf"

    mkdir -p "${SYSTEMD_DOCKER_DIR}"

    echo "[Service]" > "$SYSTEMD_DOCKER_PROXY"
    if [ -n "${HTTP_PROXY:-}" ]; then
        echo "Environment=\"HTTP_PROXY=${HTTP_PROXY}\"" >> "$SYSTEMD_DOCKER_PROXY"
    fi
    if [ -n "${HTTPS_PROXY:-}" ]; then
        echo "Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"" >> "$SYSTEMD_DOCKER_PROXY"
    fi
    if [ -n "${NO_PROXY:-}" ]; then
        echo "Environment=\"NO_PROXY=${NO_PROXY_DEFAULT},${NO_PROXY}\"" >> "$SYSTEMD_DOCKER_PROXY"
    fi
}

setup_registry_mirrors_for_docker() {
    DAEMON_JSON=/etc/docker/daemon.json

    if [ -z "${DOCKER_REGISTRY_PROXY:-}" ]; then
        #rm -f "$DAEMON_JSON"
        return 0
    fi

    insecure=""
    mirrors=""

    IFS=',' read -r -a array <<< "$DOCKER_REGISTRY_PROXY"
    for url in "${array[@]}"; do
        mirrors+="\"$url\", "
        if [[ "$url" == "http://"* ]]; then
            host_port=${url#http://}
            insecure+="\"$host_port\", "
        fi
    done

    # remove last comma
    insecure="${insecure%, }"
    mirrors="${mirrors%, }"

    if [ -n "$insecure" ]; then
        cat <<EOF > $DAEMON_JSON
{
  "insecure-registries": [${insecure}],
  "registry-mirrors": [${mirrors}]
}
EOF
    else
        cat <<EOF > $DAEMON_JSON
{
  "registry-mirrors": [${mirrors}]
}
EOF
    fi
}

setup_http_proxy_for_docker
setup_registry_mirrors_for_docker

sudo systemctl daemon-reload
sudo systemctl restart docker
