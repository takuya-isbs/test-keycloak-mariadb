#!/bin/bash
set -eu
set -x

apt-get install -y python3-pip
pip3 install python-keycloak

# RHEL
#SYSTEM_CERT_DIR=/usr/share/pki/ca-trust-source/anchors
#SYSTEM_CERT_UPDATE=update-ca-trust
#SYSTEM_CERT_BUNDLE=/etc/pki/tls/cert.pem

# Debian|Ubuntu
SYSTEM_CERT_DIR=/usr/local/share/ca-certificates
SYSTEM_CERT_UPDATE=update-ca-certificates
SYSTEM_CERT_BUNDLE=/etc/ssl/certs/ca-certificates.crt

CA_SRC=/SHARE/certs/minica.pem
CA_DST="${SYSTEM_CERT_DIR}/testca.crt"

cp -fp "$CA_SRC" "$CA_DST"
chmod 644 "$CA_DST"
chown root:root "$CA_DST"

$SYSTEM_CERT_UPDATE

echo "Execute: export SYSTEM_CERT_BUNDLE=${SYSTEM_CERT_BUNDLE}"
