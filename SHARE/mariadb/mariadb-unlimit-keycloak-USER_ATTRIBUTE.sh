#!/bin/sh
set -eu
set -x

# for Keycloak 23 or earlier

mariadb -u root -vvv <<"EOF"
use keycloak;
show columns from USER_ATTRIBUTE;
alter table USER_ATTRIBUTE drop index if exists IDX_USER_ATTRIBUTE_NAME;
#alter table USER_ATTRIBUTE drop index IDX_USER_ATTRIBUTE_NAME;
alter table USER_ATTRIBUTE modify VALUE TEXT(100000) CHARACTER SET utf8 COLLATE utf8_general_ci;
alter table USER_ATTRIBUTE ADD KEY `IDX_USER_ATTRIBUTE_NAME` (`NAME`, VALUE(400));
show columns from USER_ATTRIBUTE;
EOF
