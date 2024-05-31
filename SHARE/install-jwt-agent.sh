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
