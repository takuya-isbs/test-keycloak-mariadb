#!/bin/sh

docker compose logs --no-color "$@" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g'
