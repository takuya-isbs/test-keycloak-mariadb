#!/usr/bin/env python3

import sys
import json
from pprint import pformat as pf

from keycloak import KeycloakAdmin
from keycloak.exceptions import KeycloakError

KEYCLOAK_URL = 'https://keycloak.example.org/auth/'
ADMIN_USERNAME = 'admin'
ADMIN_PASSWORD = 'admin'
REALM = 'HPCI'
REALM_MASTER = 'master'
CLIENT_SECRET = 'aRbmg6oLjjDa2OZnpy8vnKeIBJjcawpa'

#VERIFY = False  #TODO True
VERIFY = True

def E(*args):
    print('Error:', *args, file=sys.stderr)

try:
    kapi = KeycloakAdmin(
        server_url=KEYCLOAK_URL,
        username=ADMIN_USERNAME,
        password=ADMIN_PASSWORD,
        realm_name=REALM_MASTER,
        user_realm_name=REALM_MASTER,
        verify=VERIFY,
    )
except KeycloakError as e:
    E(e.error_message)
    sys.exit(1)

# REALM
realms = kapi.get_realms()
realm_names = [realm['realm'] for realm in realms]

if REALM in realm_names:
    print(f'create realm "{REALM}": already exists')
else:
    new_realm = {
        'realm': REALM,
        'enabled': True
    }
    kapi.create_realm(new_realm)

try:
    kapi = KeycloakAdmin(
        server_url=KEYCLOAK_URL,
        username=ADMIN_USERNAME,
        password=ADMIN_PASSWORD,
        realm_name=REALM,
        user_realm_name=REALM_MASTER,
        verify=VERIFY,
    )
except KeycloakError as e:
    E(e.error_message)
    sys.exit(1)

# PUT /admin/realms/{realm}/events/config
event_config = '''
{
  "eventsEnabled" : true,
  "eventsListeners" : [ "jboss-logging" ],
  "enabledEventTypes" : [ "SEND_RESET_PASSWORD",
  "UPDATE_CONSENT_ERROR", "GRANT_CONSENT", "VERIFY_PROFILE_ERROR",
  "REMOVE_TOTP", "REVOKE_GRANT", "UPDATE_TOTP", "LOGIN_ERROR",
  "CLIENT_LOGIN", "RESET_PASSWORD_ERROR", "IMPERSONATE_ERROR",
  "CODE_TO_TOKEN_ERROR", "CUSTOM_REQUIRED_ACTION",
  "OAUTH2_DEVICE_CODE_TO_TOKEN_ERROR", "RESTART_AUTHENTICATION",
  "IMPERSONATE", "UPDATE_PROFILE_ERROR", "LOGIN",
  "OAUTH2_DEVICE_VERIFY_USER_CODE", "UPDATE_PASSWORD_ERROR",
  "CLIENT_INITIATED_ACCOUNT_LINKING", "TOKEN_EXCHANGE",
  "AUTHREQID_TO_TOKEN", "LOGOUT", "REGISTER", "DELETE_ACCOUNT_ERROR",
  "CLIENT_REGISTER", "IDENTITY_PROVIDER_LINK_ACCOUNT",
  "DELETE_ACCOUNT", "UPDATE_PASSWORD", "CLIENT_DELETE",
  "FEDERATED_IDENTITY_LINK_ERROR", "IDENTITY_PROVIDER_FIRST_LOGIN",
  "CLIENT_DELETE_ERROR", "VERIFY_EMAIL", "CLIENT_LOGIN_ERROR",
  "RESTART_AUTHENTICATION_ERROR", "EXECUTE_ACTIONS",
  "REMOVE_FEDERATED_IDENTITY_ERROR", "TOKEN_EXCHANGE_ERROR",
  "PERMISSION_TOKEN", "SEND_IDENTITY_PROVIDER_LINK_ERROR",
  "EXECUTE_ACTION_TOKEN_ERROR", "SEND_VERIFY_EMAIL",
  "OAUTH2_DEVICE_AUTH", "EXECUTE_ACTIONS_ERROR",
  "REMOVE_FEDERATED_IDENTITY", "OAUTH2_DEVICE_CODE_TO_TOKEN",
  "IDENTITY_PROVIDER_POST_LOGIN",
  "IDENTITY_PROVIDER_LINK_ACCOUNT_ERROR",
  "OAUTH2_DEVICE_VERIFY_USER_CODE_ERROR", "UPDATE_EMAIL",
  "REGISTER_ERROR", "REVOKE_GRANT_ERROR", "EXECUTE_ACTION_TOKEN",
  "LOGOUT_ERROR", "UPDATE_EMAIL_ERROR", "CLIENT_UPDATE_ERROR",
  "AUTHREQID_TO_TOKEN_ERROR", "UPDATE_PROFILE",
  "CLIENT_REGISTER_ERROR", "FEDERATED_IDENTITY_LINK",
  "SEND_IDENTITY_PROVIDER_LINK", "SEND_VERIFY_EMAIL_ERROR",
  "RESET_PASSWORD", "CLIENT_INITIATED_ACCOUNT_LINKING_ERROR",
  "OAUTH2_DEVICE_AUTH_ERROR", "UPDATE_CONSENT", "REMOVE_TOTP_ERROR",
  "VERIFY_EMAIL_ERROR", "SEND_RESET_PASSWORD_ERROR", "CLIENT_UPDATE",
  "CUSTOM_REQUIRED_ACTION_ERROR",
  "IDENTITY_PROVIDER_POST_LOGIN_ERROR", "UPDATE_TOTP_ERROR",
  "CODE_TO_TOKEN", "VERIFY_PROFILE", "GRANT_CONSENT_ERROR",
  "IDENTITY_PROVIDER_FIRST_LOGIN_ERROR" ],

 "adminEventsEnabled" : true,
 "adminEventsDetailsEnabled" : false
}
'''
kapi.set_events(json.loads(event_config))
print('update events/config')

realm_config = '''
{
  "enabled": true,
  "loginWithEmailAllowed": false,
  "defaultSignatureAlgorithm": "ES256",
  "ssoSessionIdleTimeout": 21600,
  "offlineSessionMaxLifespanEnabled": true,
  "offlineSessionMaxLifespan": 604800,
  "accessTokenLifespan": 600,
  "oauth2DeviceCodeLifespan": 300,
  "oauth2DevicePollingInterval": 10
}
'''
kapi.update_realm(REALM, json.loads(realm_config))
print('update REALM')

realm = kapi.get_realm(REALM)
#print(realm)
realm_id = realm['id']
print(f'realm_id={realm_id}')

keys = kapi.get_keys()
#print(keys)
algorithms = []
for key in keys['keys']:
    algorithms.append(key['algorithm'])
ES256 = 'ES256'
if ES256 in algorithms:
    print(f'create key "{ES256}": already exist')
else:
    component = {
        "name": "ecdsa-generated",
        "providerId": "ecdsa-generated",
        "providerType": "org.keycloak.keys.KeyProvider",
        "parentId": realm_id,
        "config": {
            "priority": ["200"],
            "enabled": ["true"],
            "active": ["true"]
        }
    }
    kapi.create_component(component)
    print(f'create key "{ES256}"')

# client scope
def create_client_scope(name):
    scope = {
        "alias": name,
        "name": name,
        "protocol": "openid-connect"
    }
    kapi.create_client_scope(scope, skip_exists=True)

def create_mapper(scope_name, mapper_name, payload):
    scope = kapi.get_client_scope_by_name(scope_name)
    print(f'client scope {scope}')
    scope_id = scope['id']
    print(f'client scope id {scope_id}')
    mappers = kapi.get_mappers_from_client_scope(scope_id)
    print('mappers: ' + pf(mappers))
    mapper_dict = {}
    for mapper in mappers:
        mapper_dict[mapper['name']] = mapper
    mapper = mapper_dict.get(mapper_name, None)
    if mapper is None:
        kapi.add_mapper_to_client_scope(scope_id, payload)
    else:
        mapper_id = mapper['id']
        print(f'mapper id {mapper_id} to update')
        payload['id'] = mapper_id  # for Uncaught server error: java.lang.NullPointerException
        kapi.update_mapper_in_client_scope(scope_id, mapper_id, payload)

scope_openid = 'openid'
mapper_nbf_name = 'nbf'
mapper_nbf = {
    "name": mapper_nbf_name,
    "protocol": "openid-connect",
    "consentRequired": False,
    "protocolMapper": "oidc-hardcoded-claim-mapper",
    "config": {
        "claim.name": mapper_nbf_name,
        "claim.value": 0,
        "jsonType.label": "int",
        "userinfo.token.claim": False,
        "id.token.claim": False,
        "access.token.claim": True,
        "access.tokenResponse.claim": False,
    }
}

scope_scitokens = 'scitokens'
mapper_ver_name = 'ver'
mapper_ver = {
    "name": mapper_ver_name,
    "protocol": "openid-connect",
    "consentRequired": False,
    "protocolMapper": "oidc-hardcoded-claim-mapper",
    "config": {
        "claim.name": mapper_nbf_name,
        "claim.value": "scitokens:2.0",
        "jsonType.label": "String",
        "userinfo.token.claim": True,
        "id.token.claim": False,
        "access.token.claim": True,
        "access.tokenResponse.claim": False,
    }
}

scope_hpci = 'hpci'
mapper_hpciver_name = 'hpci.ver'
mapper_hpciver = {
    "name": mapper_hpciver_name,
    "protocol": "openid-connect",
    "consentRequired": False,
    "protocolMapper": "oidc-hardcoded-claim-mapper",
    "config": {
        "claim.name": "hpci\.ver",
        "claim.value": "1.0",
        "jsonType.label": "String",
        "userinfo.token.claim": True,
        "id.token.claim": False,
        "access.token.claim": True,
        "access.tokenResponse.claim": False,
    }
}

mapper_hpciid_name = 'hpci.id'
mapper_hpciid = {
    "name": mapper_hpciid_name,
    "protocol": "openid-connect",
    "consentRequired": False,
    "protocolMapper": "oidc-usermodel-attribute-mapper",
    "config": {
        "claim.name": "hpci\.id",
        "user.attribute": "hpci.id",
        "jsonType.label": "String",
        "userinfo.token.claim": True,
        "id.token.claim": False,
        "access.token.claim": True,
    }
}

mapper_hpciglobal_name = 'hpci-global'
mapper_hpciglobal = {
    "name": mapper_hpciglobal_name,
    "protocol": "openid-connect",
    "consentRequired": False,
    "protocolMapper": "oidc-audience-mapper",
    "config": {
        "id.token.claim": False,
        "access.token.claim": True,
        "included.custom.audience": "hpci",
    }
}

create_client_scope(scope_openid)
create_mapper(scope_openid, mapper_nbf_name, mapper_nbf)
create_client_scope(scope_scitokens)
create_mapper(scope_scitokens, mapper_ver_name, mapper_ver)
create_client_scope(scope_hpci)
create_mapper(scope_hpci, mapper_hpciver_name, mapper_hpciver)
create_mapper(scope_hpci, mapper_hpciid_name, mapper_hpciid)
create_mapper(scope_hpci, mapper_hpciglobal_name, mapper_hpciglobal)

# client



print('DONE')
