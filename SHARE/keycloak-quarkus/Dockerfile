ARG KEYCLOAK_IMAGE=keycloak/keycloak:24.0
FROM $KEYCLOAK_IMAGE as builder

# RUN /opt/keycloak/bin/kc.sh build

# FROM $KEYCLOAK_IMAGE
# COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/

WORKDIR /opt/keycloak

# Configuring distributed caches
# SEE: https://www.keycloak.org/server/caching
ENV KC_CACHE_CONFIG_FILE=cache-ispn-tcpping.xml
COPY ./${KC_CACHE_CONFIG_FILE} /opt/keycloak/conf/${KC_CACHE_CONFIG_FILE}

#RUN /opt/keycloak/bin/kc.sh build --cache-config-file="${KC_CACHE_CONFIG_FILE}"

ENV KC_METRICS_ENABLED=true

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--cache-config-file=${KC_CACHE_CONFIG_FILE}"]
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--cache-config-file=${KC_CACHE_CONFIG_FILE}"]
