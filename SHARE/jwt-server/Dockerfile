FROM rockylinux/rockylinux:9

RUN dnf -y update \
 && dnf -y install \
 git java-devel tomcat maven mariadb

RUN git clone https://github.com/oss-tsukuba/jwt-server.git

RUN cd jwt-server \
 && mvn package \
 && cp target/jwt-server.war /usr/share/tomcat/webapps/ROOT.war

COPY run-tomcat.sh /run-tomcat.sh
COPY jwt-server-sql.sh /jwt-server-sql.sh
COPY update-ca.sh /update-ca.sh
CMD ["sh", "/run-tomcat.sh"]
