#!/bin/sh

set -eu
set -x

sh /jwt-server-sql.sh
sh /update-ca.sh

. /etc/tomcat/tomcat.conf
. /etc/sysconfig/tomcat
/usr/libexec/tomcat/server start
