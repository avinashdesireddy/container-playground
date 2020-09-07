import json
import sys
import time
import urllib3

import requests

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

### AUTH

def login(url, user, password):
    r = requests.post('https://{}/id/login'.format(url), verify=False, json={"username": user, "password": password})
    r.raise_for_status()
    return r.json()['sessionToken']


### BACKUP

def get_users(url, session_token):
    r = requests.get('https://{}/accounts/{}'.format(url, username), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    print(r.json())

def get_user_id(url, session_token, username):
    r = requests.get('https://{}/accounts/{}'.format(url, username), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()['id']

def get_orgs(url, token):
    r = requests.get('https://{}/accounts?filter=orgs&limit=50'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_user_id(url, token, user):
    r = requests.get('https://{}/accounts/{}'.format(url, user), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()['id']

def get_org_admin_sync(url, token, org_name):
    r = requests.get('https://{}/accounts/{}/adminMemberSyncConfig'.format(url, org_name), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_teams_in_org(url, token, org_name):
    r = requests.get('https://{}/accounts/{}/teams'.format(url, org_name), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_org_team_sync(url, token, org_name, team_name):
    r = requests.get('https://{}/accounts/{}/teams/{}/memberSyncConfig'.format(url, org_name, team_name), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_roles(url, token):
    r = requests.get('https://{}/roles'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_collections(url, token):
    r = requests.get('https://{}/collections?limit=100'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()

def get_grants(url, token):
    r = requests.get('https://{}/collectionGrants?subjectType=all&expandUser=false&showPaths=false&limit=200'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()
    return r.json()


### RESTORE

def create_org(url, token, org_name):
    payload = {
        "isOrg": True,
        "name": org_name
    }
    r = requests.post('https://{}/accounts'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=payload)
    r.raise_for_status()
    return r.json()['id']

def set_org_admin_sync(url, token, org_name, data):
    r = requests.put('https://{}/accounts/{}/adminMemberSyncConfig'.format(url, org_name), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=data)
    r.raise_for_status()

def create_team(url, token, org_name, team_name):
    payload = {
        "description": team_name,
        "name": team_name
    }
    r = requests.post('https://{}/accounts/{}/teams'.format(url, org_name), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=payload)
    r.raise_for_status()
    return r.json()['id']

def set_org_team_sync(url, token, org_name, team_name, data):
    r = requests.put('https://{}/accounts/{}/teams/{}/memberSyncConfig'.format(url, org_name, team_name), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=data)
    r.raise_for_status()

def create_role(url, token, data):
    r = requests.post('https://{}/roles'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=data)
    r.raise_for_status()
    return r.json()['id']

def create_collection(url, token, payload):
    r = requests.post('https://{}/collections'.format(url), verify=False, headers={"Authorization": "Bearer {}".format(token)}, json=payload)
    r.raise_for_status()
    return r.json()['id']

def create_grant(url, token, subject_id, object_id, role_id):
    r = requests.put('https://{}/collectionGrants/{}/{}/{}'.format(url, subject_id, object_id, role_id), verify=False, headers={"Authorization": "Bearer {}".format(token)})
    r.raise_for_status()


### LOGIC

def get_collection_id_by_path(collections, path):
    print(path)
    print(json.dumps(collections))
    for collection in collections:
        if collection['path'] == path:
            return collection['id']
    sys.exit("Error finding collection path.")

def get_org_id_by_name(orgs, name):
    for org in orgs:
        if org['name'] == name:
            return org['id']
    sys.exit("Error finding org name.")


### MAIN

if __name__ == '__main__':
    url = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    session_token = login(url, username, password)
    get_users(url, session_token)
