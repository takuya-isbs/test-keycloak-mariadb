#!/bin/bash
set -eu
DEBUG=0
source ./common.sh

CACERT=certs/minica.pem
TIMEOUT=3

LXC_EXEC() {
    $LXC exec --cwd /SHARE "$@"
}

CURL_SQUID() {
    https_proxy=http://10.60.204.104:13128 curl -s --connect-timeout $TIMEOUT --cacert SHARE/${CACERT} -L "$@"
}

CURL_LXD() {
    local CONT_NAME="$1"
    local url_host="$2"
    local url="$3"
    LXC_EXEC $CONT_NAME -- curl -s curl -s --connect-timeout $TIMEOUT --cacert /SHARE/${CACERT} -L --resolve "${url_host}:443:127.0.0.1" "$url"
}

ERR() {
    echo >&2 "Error: $@"
}

CHECK() {
    local status="$1"
    local expect="$2"
    local name="$3"
    if [ "$status" = "$expect" ]; then
        echo "OK: $name"
    else
        ERR "$name"
    fi
}

KEYCLOAK=keycloak.example.org
JWT_SERVER=jwtserver.example.org

KC_HEALTH=https://${KEYCLOAK}/auth/health
JS_HEALTH=https://${JWT_SERVER}/menu/

date
VIP_HOST=
for HOST in $DB_HOSTS; do
    FULLNAME=${PROJECT}-${HOST}
    #CURL_LXD $FULLNAME $KEYCLOAK $KC_HEALTH
    status=$(CURL_LXD $FULLNAME $KEYCLOAK $KC_HEALTH | jq -r .status || true)
    CHECK $status "UP" "(from $FULLNAME) $KC_HEALTH"
    #CURL_LXD $FULLNAME $JWT_SERVER $JS_HEALTH
    status=$(CURL_LXD $FULLNAME $JWT_SERVER $JS_HEALTH | grep JWT-SERVER | wc -l || true)
    CHECK $status "1" "(from $FULLNAME) $JS_HEALTH"
    status=$(LXC_EXEC $FULLNAME -- docker compose exec mariadb mariadb-admin ping | grep "is alive" | wc -l || true)
    CHECK $status "1" "(from $FULLNAME) mariadb"

    if [ -z "$VIP_HOST" ]; then
        ips=$($LXC exec $FULLNAME /SHARE/myip.sh)
        for ip in $ips; do
            if [ "$ip" = "$VIP" ]; then
                VIP_HOST=$FULLNAME
                break
            fi
        done
    fi
done

# VIP
status=$(CURL_SQUID $KC_HEALTH | jq -r .status || true)
CHECK $status "UP" "(from VIP,$VIP_HOST) $KC_HEALTH"
status=$(CURL_SQUID $JS_HEALTH | grep JWT-SERVER | wc -l || true)
CHECK $status "1" "(from VIP,$VIP_HOST) $JS_HEALTH"
