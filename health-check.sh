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
    local url="$2"
    local host1="$3"
    local host2="$4"
    LXC_EXEC $CONT_NAME -- curl -s curl -s --connect-timeout $TIMEOUT --cacert /SHARE/${CACERT} -L --resolve "${host1}:443:127.0.0.1" --resolve "${host2}:443:127.0.0.1" "$url"
}

ERR() {
    echo >&2 "Error: $@"
}

ERROR_COUNT=0

CHECK() {
    local status="$1"
    local expect="$2"
    local name="$3"
    if [ "$status" = "$expect" ]; then
        echo "OK: $name"
    else
        ERR "$name"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
}

IS_JWTSERVER() {
    grep "<title>Sign in to " | wc -l
}

KEYCLOAK_HOSTNAME=keycloak.example.org
JWT_SERVER_HOSTNAME=jwtserver.example.org

REALM=HPCI

KC_HEALTH=https://${KEYCLOAK_HOSTNAME}/auth/health
#KC_HEALTH=https://${KEYCLOAK_HOSTNAME}/auth/realms/${REALM}/
JS_HEALTH=https://${JWT_SERVER_HOSTNAME}/menu/

date
VIP_HOST=
for HOST in $DB_HOSTS; do
    FULLNAME=${PROJECT}-${HOST}
    #CURL_LXD $FULLNAME $KC_HEALTH $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME
    status=$(CURL_LXD $FULLNAME $KC_HEALTH $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME | jq -r .status || true)
    CHECK "$status" "UP" "(from $FULLNAME) $KC_HEALTH"
    #CURL_LXD $FULLNAME $JS_HEALTH $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME
    status=$(CURL_LXD $FULLNAME $JS_HEALTH $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME | IS_JWTSERVER || true)
    CHECK "$status" "1" "(from $FULLNAME) $JS_HEALTH"
    status=$(LXC_EXEC $FULLNAME -- docker compose exec mariadb mariadb-admin ping | grep "is alive" | wc -l || true)
    CHECK "$status" "1" "(from $FULLNAME) mariadb"

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
CHECK "$status" "UP" "(from VIP,$VIP_HOST) $KC_HEALTH"
status=$(CURL_SQUID $JS_HEALTH | IS_JWTSERVER || true)
CHECK "$status" "1" "(from VIP,$VIP_HOST) $JS_HEALTH"

exit $ERROR_COUNT
