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

USE_KC_HEALTH_URL=0

KC_HEALTH_URL=https://${KEYCLOAK_HOSTNAME}/auth/health
KC_REALM_URL=https://${KEYCLOAK_HOSTNAME}/auth/realms/${REALM}/
JS_HEALTH_URL=https://${JWT_SERVER_HOSTNAME}/menu/

CHECK_KC_HEALTH() {
    local name="$1"

    if [ $USE_KC_HEALTH_URL = 1 ]; then
	local json=$(CURL_LXD $name $KC_HEALTH_URL $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME)
	#echo $json
	local status=$(echo "$json" | jq -r .status || true)
	CHECK "$status" "UP" "(from $name) $KC_HEALTH_URL"
    else
	local json=$(CURL_LXD $name $KC_REALM_URL $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME)
	local status=$(echo "$json" | jq -r .realm || true)
	CHECK "$status" "$REALM" "(from $name) $KC_REALM_URL"
    fi
}

date
VIP_HOST=
for HOST in $DB_HOSTS; do
    FULLNAME=${PROJECT}-${HOST}

    CHECK_KC_HEALTH $FULLNAME

    json=$(CURL_LXD $FULLNAME $JS_HEALTH_URL $KEYCLOAK_HOSTNAME $JWT_SERVER_HOSTNAME)
    #echo "$json"
    status=$(echo "$json" | IS_JWTSERVER || true)
    CHECK "$status" "1" "(from $FULLNAME) $JS_HEALTH_URL"

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
if [ $USE_KC_HEALTH_URL = 1 ]; then
    json=$(CURL_SQUID $KC_HEALTH_URL)
    status=$(echo "$json" | jq -r .status || true)
    CHECK "$status" "UP" "(from VIP,$VIP_HOST) $KC_HEALTH_URL"
else
    json=$(CURL_SQUID $KC_REALM_URL)
    status=$(echo "$json" | jq -r .realm || true)
    CHECK "$status" "$REALM" "(from VIP,$VIP_HOST) $KC_REALM_URL"
fi

json=$(CURL_SQUID $JS_HEALTH_URL)
status=$(echo "$json" | IS_JWTSERVER || true)
CHECK "$status" "1" "(from VIP,$VIP_HOST) $JS_HEALTH_URL"

exit $ERROR_COUNT
