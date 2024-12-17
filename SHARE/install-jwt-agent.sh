#!/bin/bash
set -eu
set -x

cd /SHARE
if [ ! -d jwt-agent ]; then
    git clone https://github.com/oss-tsukuba/jwt-agent.git
fi
cd jwt-agent

apt-get install -y golang

make
make PREFIX=/usr/local install

JWTPARSE_URL="https://raw.githubusercontent.com/oss-tsukuba/gfarm/refs/heads/2.8/util/jwt-parse/jwt-parse"
JWTPARSE_BIN=/usr/local/bin/jwt-parse

curl -o $JWTPARSE_BIN $JWTPARSE_URL
chmod +x $JWTPARSE_BIN
