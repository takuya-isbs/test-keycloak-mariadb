#!/bin/sh
set -eu
set -x

# SEE ALSO: keycloak-init.py, docker-compose.yml
URL=http://localhost:8080/auth/
ADMIN_REALM=master
REALM=hpci
USER=admin
PASSWORD=admin

KCADM="docker compose exec -T keycloak /opt/keycloak/bin/kcadm.sh"

$KCADM config credentials --server $URL --realm $ADMIN_REALM --user $USER --password $PASSWORD

#$KCADM get users/profile -r $REALM

$KCADM update users/profile -r $REALM -f - <<'EOF'
{
  "attributes" : [ {
    "name" : "username",
    "displayName" : "${username}",
    "validations" : {
      "length" : {
        "min" : 3,
        "max" : 255
      },
      "username-prohibited-characters" : { },
      "up-username-not-idn-homograph" : { }
    },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  }, {
    "name" : "email",
    "displayName" : "${email}",
    "validations" : {
      "email" : { },
      "length" : {
        "max" : 255
      }
    },
    "required" : {
      "roles" : [ "user" ]
    },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  }, {
    "name" : "firstName",
    "displayName" : "${firstName}",
    "validations" : {
      "length" : {
        "max" : 255
      },
      "person-name-prohibited-characters" : { }
    },
    "required" : {
      "roles" : [ "user" ]
    },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  }, {
    "name" : "lastName",
    "displayName" : "${lastName}",
    "validations" : {
      "length" : {
        "max" : 255
      },
      "person-name-prohibited-characters" : { }
    },
    "required" : {
      "roles" : [ "user" ]
    },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  }, {
    "name" : "hpci.id",
    "displayName" : "${hpci.id}",
    "validations" : { },
    "annotations" : { },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  }, {
    "name" : "local-accounts",
    "displayName" : "${local-accounts}",
    "validations" : { },
    "annotations" : { },
    "permissions" : {
      "view" : [ "admin", "user" ],
      "edit" : [ "admin" ]
    },
    "multivalued" : false
  } ],
  "groups" : [ {
    "name" : "user-metadata",
    "displayHeader" : "User metadata",
    "displayDescription" : "Attributes, which refer to user metadata"
  } ]
}
EOF

$KCADM get users/profile -r $REALM

#$KCADM get users/7f90e03b-a3e0-45f1-b6c9-5855e8f7858e -r $REALM
