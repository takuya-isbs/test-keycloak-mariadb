#!/bin/sh

UIDGID="$1"

MINICA="docker run --user $UIDGID -it --rm -v /SHARE/certs:/output ruanbekker/minica"

$MINICA --domains keycloak.example.org,jwtserver.example.org
$MINICA --domains dummy.example.org
