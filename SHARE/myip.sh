#!/bin/sh

interface=`ip route | awk '/^default/ { print $5 }'`
ip addr show $interface | awk '/inet / {print $2}' | cut -d '/' -f 1
