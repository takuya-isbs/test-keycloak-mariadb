# REFERENCE: https://github.com/oss-tsukuba/gfarm/blob/2.8/docker/dist/jwt-server/jwt-server/Dockerfile

FROM rockylinux/rockylinux:9
#FROM almalinux/almalinux:9

RUN dnf -y update \
 && dnf -y install \
 git java-21-openjdk-devel maven mariadb wget

RUN alternatives --set java java-21-openjdk.x86_64
RUN alternatives --set javac java-21-openjdk.x86_64

ARG TOMCAT_VER=10.1.34
ARG JWT_SERVER_VER=1.1.0

RUN wget https://archive.apache.org/dist/tomcat/tomcat-10/v$TOMCAT_VER/bin/apache-tomcat-$TOMCAT_VER.tar.gz
RUN tar -xvf apache-tomcat-$TOMCAT_VER.tar.gz -C /opt
RUN ln -s /opt/apache-tomcat-$TOMCAT_VER /opt/tomcat

RUN useradd -s /sbin/nologin tomcat
RUN chown -R tomcat: /opt/apache-tomcat-$TOMCAT_VER
RUN sh -c 'chmod +x /opt/tomcat/bin/*.sh'

RUN rm -rf /opt/tomcat/webapps/*

RUN git clone --branch $JWT_SERVER_VER https://github.com/oss-tsukuba/jwt-server.git

#COPY application.properties /jwt-server/src/main/resources/
RUN sed -i 's/${KEYCLOAK}:443/${KEYCLOAK}/' /jwt-server/src/main/resources/application.properties

ENV JAVA_HOME="/usr/lib/jvm/java"

RUN cd jwt-server \
 && mvn package \
 && cp target/jwt-server.war /opt/tomcat/webapps/ROOT.war

COPY run-tomcat.sh /run-tomcat.sh
COPY jwt-server-sql.sh /jwt-server-sql.sh
COPY update-ca.sh /update-ca.sh
CMD ["sh", "/run-tomcat.sh"]
