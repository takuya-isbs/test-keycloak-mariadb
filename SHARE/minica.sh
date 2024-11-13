#!/bin/sh
set -eu
set -x

UIDGID="$1"
CERTS_DIR=/SHARE/certs

#MINICA="docker run --user $UIDGID -it --rm -v ${CERTS_DIR}:/output ruanbekker/minica"
MINICA="docker run --user $UIDGID -it --rm -v ${CERTS_DIR}:/output ryantk/minica"

if [ -f ${CERTS_DIR}/minica-key.pem ]; then
    exit 0
fi

$MINICA --domains keycloak.example.org,jwtserver.example.org
$MINICA --domains dummy.example.org
