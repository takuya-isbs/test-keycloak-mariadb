ARG KEYCLOAK_IMAGE=keycloak/keycloak:24.0
FROM $KEYCLOAK_IMAGE as builder

RUN /opt/keycloak/bin/kc.sh build

# https://gist.github.com/xgp/768eea11f92806b9c83f95902f7f8f80
# copy the custom cache config file into the keycloak conf dir
#COPY ./cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml

FROM $KEYCLOAK_IMAGE
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
WORKDIR /opt/keycloak

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
