#!/bin/sh

docker compose exec -u root keycloak cat /opt/jboss/keycloak/standalone/configuration/standalone-ha.xml |less
