#!/bin/sh

set -eu
set -x

sh /jwt-server-sql.sh
sh /update-ca.sh

TOMCAT_SERVERXML=/etc/tomcat/server.xml
BAK=${TOMCAT_SERVERXML}.bak

if [ -f $BAK ]; then
    cp -fp $BAK $TOMCAT_SERVERXML
else
    cp -fp $TOMCAT_SERVERXML $BAK
fi
# set "https" for redirect_uri from Keycloak
sed -i '/<\/Host>/i \        <Valve className="org.apache.catalina.valves.RemoteIpValve" protocolHeader="x-forwarded-proto"/>' $TOMCAT_SERVERXML

. /etc/tomcat/tomcat.conf
. /etc/sysconfig/tomcat
/usr/libexec/tomcat/server start
