#!/bin/sh

set -eu
set -x

sh /jwt-server-sql.sh
sh /update-ca.sh

TOMCAT_SECRET=TQJvCWhkNjULELwF
TOMCAT_SERVERXML=/opt/tomcat/conf/server.xml
BAK=${TOMCAT_SERVERXML}.bak

if [ -f $BAK ]; then
    cp -fp $BAK $TOMCAT_SERVERXML
else
    cp -fp $TOMCAT_SERVERXML $BAK
fi

sed -i '/<Connector port="8080" protocol="HTTP\/1.1"/,/maxParameterCount="1000" \/>/{N;s/<Connector port="8080" protocol="HTTP\/1.1"/<\!\-\-\n    <Connector port="8080" protocol="HTTP\/1.1"/}' $TOMCAT_SERVERXML
sed -i '/<Connector port="8080" protocol="HTTP\/1.1"/,/\/>/{N;s/\/>/\/>\n \-\->/}' $TOMCAT_SERVERXML
sed -i '/<\!\-\- Define an AJP 1.3 Connector on port 8009 \-\->/,/\-\->\/>/{N;s/<\!\-\-$//}' $TOMCAT_SERVERXML
sed -i '/<\!\-\- Define an AJP 1.3 Connector on port 8009 \-\->/,/\-\->\/>/{N;s/address="::1"/address="0.0.0.0"/}' $TOMCAT_SERVERXML
sed -i "/<\!\-\- Define an AJP 1.3 Connector on port 8009 \-\->/,/\-\->\/>/{N;s;maxParameterCount=\"1000\";maxParameterCount=\"1000\" \n               secret=\"$TOMCAT_SECRET\";}" $TOMCAT_SERVERXML
sed -i '/Define an AJP 1.3 Connector on port 8009 -->$/,/Engine represents/ s/    -->\s*//' $TOMCAT_SERVERXML

# set "https" for redirect_uri from Keycloak
sed -i '/<\/Host>/i \        <Valve className="org.apache.catalina.valves.RemoteIpValve" protocolHeader="x-forwarded-proto"/>' $TOMCAT_SERVERXML

exec /opt/tomcat/bin/catalina.sh run
