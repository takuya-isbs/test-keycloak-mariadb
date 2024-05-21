#!/bin/bash
set -e
source ./common.sh

lxc exec $HOST1 sh /SHARE/minica.sh "$(id -u):$(id -g)"
