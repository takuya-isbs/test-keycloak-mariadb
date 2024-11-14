#!/bin/bash
set -eu
#set -x

SYSTEM_CERT_BUNDLE=/etc/ssl/certs/ca-certificates.crt
VENV_DIR=${HOME}/venv

KEYCLOAK_URL=https://keycloak.example.org/auth/

export https_proxy=http://localhost:13128

#TODO in keycloak-init.py
get_code() {
    curl -s -k -L -w '%{http_code}' "$1" -o /dev/null
}
wait_for_keycloak_startup() {
    local URL="$1"
    local EXPECT='^[23]0.*$'
    while :; do
        if CODE=$(get_code "$URL"); then
            if [[ "$CODE" =~ ${EXPECT} ]]; then
                break
            fi
        fi
        sleep 1
        echo -n "."
    done
}
echo
wait_for_keycloak_startup $KEYCLOAK_URL

. ${VENV_DIR}/bin/activate
export REQUESTS_CA_BUNDLE=${SYSTEM_CERT_BUNDLE}
python3 keycloak-init.py
