#!/bin/sh

set -eu
set -x

MYSQL="mysql -h ${MYSQL_HOST} -u ${USER} -p${PASSWORD} ${DB}"

$MYSQL < /jwt-server/ddl/jwt-server.ddl

$MYSQL <<EOF
ALTER DATABASE ${DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT CONCAT('ALTER TABLE ', TABLE_NAME, ' CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
FROM INFORMATION_SCHEMA.TABLES
     WHERE TABLE_SCHEMA = '${DB}';

SELECT CONCAT('ALTER TABLE ', TABLE_NAME, ' MODIFY ', COLUMN_NAME, ' ', COLUMN_TYPE, ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '${DB}' AND DATA_TYPE LIKE '%char%';
EOF

$MYSQL <<EOF
SELECT
    SCHEMA_NAME,
    DEFAULT_CHARACTER_SET_NAME,
    DEFAULT_COLLATION_NAME
FROM
    INFORMATION_SCHEMA.SCHEMATA
WHERE
    SCHEMA_NAME = '${DB}';
EOF
