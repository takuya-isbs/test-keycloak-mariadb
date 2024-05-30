FROM rockylinux/rockylinux:9

RUN dnf -y update \
 && dnf -y install \
 git java-devel tomcat maven mariadb

RUN git clone https://github.com/oss-tsukuba/jwt-server.git

#ARG KEYCLOAK_VERSION=20.0.1  # NG for Keycloak server 24
#ARG KEYCLOAK_VERSION=21.0.0  # NG
#ARG KEYCLOAK_VERSION=22.0.0  # NG
#ARG KEYCLOAK_VERSION=23.0.0  # OK
ARG KEYCLOAK_VERSION=24.0.4  # OK

RUN cd jwt-server \
 && sed -i "s|<keycloak.version>[^<]*</keycloak.version>|<keycloak.version>${KEYCLOAK_VERSION}</keycloak.version>|" pom.xml \
 && mvn package \
 && cp target/jwt-server.war /usr/share/tomcat/webapps/ROOT.war

COPY run-tomcat.sh /run-tomcat.sh
COPY jwt-server-sql.sh /jwt-server-sql.sh
COPY update-ca.sh /update-ca.sh
CMD ["sh", "/run-tomcat.sh"]
