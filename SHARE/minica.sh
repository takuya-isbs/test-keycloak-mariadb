#!/bin/sh

docker run --user "$(id -u):$(id -g)" -it --rm -v $PWD/certs:/output ruanbekker/minica --domains keycloak.example.org,jwtserver.example.org
