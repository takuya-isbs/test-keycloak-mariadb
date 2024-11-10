#!/bin/bash
set -eu

# by root
mariadb -u root -vvv <<EOF
SET @username = '${JWTSERVER_DB_USER}';
SET @host = '%';
SET @password = '${JWTSERVER_DB_PASSWORD}';

SELECT EXISTS (
    SELECT 1
    FROM mysql.user
    WHERE user = @username AND host = @host
) INTO @user_exists;

SET @sql = IF(@user_exists,
              CONCAT('ALTER USER ''', @username, '''@''', @host, ''' IDENTIFIED BY ''', @password, ''';'),
              CONCAT('CREATE USER ''', @username, '''@''', @host, ''' IDENTIFIED BY ''', @password, ''';'));

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql_grant_privileges = CONCAT('GRANT ALL PRIVILEGES ON *.* TO \'', @username, '\'@\'', @host, '\' WITH GRANT OPTION;');
PREPARE stmt FROM @sql_grant_privileges;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE DATABASE IF NOT EXISTS ${JWTSERVER_DB};
EOF
