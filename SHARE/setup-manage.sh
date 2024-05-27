#!/bin/bash

. /SHARE/_config.sh

export DOCKER_USER
export DOCKER_PASS

COMPOSE="docker compose -f ./compose-manage.yml"

cd /SHARE/
$COMPOSE down
$COMPOSE up -d
