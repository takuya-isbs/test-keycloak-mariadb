#!/bin/sh
set -eu

./00_init.sh
./01_create-hosts.sh
./02_install.sh
./03_ca.sh
./LIST.sh

./04_setup.sh
