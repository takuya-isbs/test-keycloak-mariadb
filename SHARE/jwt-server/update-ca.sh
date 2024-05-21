#!/bin/sh

set -eu
set -x

update-ca-trust
keytool -noprompt -import -cacerts -storepass changeit -alias minica \
	-file /usr/share/pki/ca-trust-source/anchors/minica.crt
