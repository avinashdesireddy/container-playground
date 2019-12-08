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
    mode = sys.argv[1]
    if mode not in ['b', 'r']:
        sys.exit("Mode must be 'b' (backup) or 'r' (restore)")
    url = sys.argv[2]
    username = sys.argv[3]
    password = sys.argv[4]
    session_token = login(url, username, password)

    if mode == 'r':
        try:
            with open('/out/backupdata.json', 'r') as infile:
                data = json.load(infile)
        except:
            sys.exit("Can't load backup file")

        id_mappings = {}

        new_collections = get_collections(url, session_token)
        new_shared = get_collection_id_by_path(new_collections, "/Shared/Private/{}".format(username))
        old_shared = get_collection_id_by_path(data['collections'], "/Shared/Private/{}".format(username))
        id_mappings[old_shared] = new_shared

        new_admin_user_id = get_user_id(url, session_token, username)
        old_admin_user_id = data['admin_login_id']
        id_mappings[old_admin_user_id] = new_admin_user_id

        new_orgs = get_orgs(url, session_token)
        new_datacenter = get_org_id_by_name(new_orgs['accounts'], 'docker-datacenter')
        old_datacenter = get_org_id_by_name(data['orgs'], 'docker-datacenter')
        id_mappings[old_datacenter] = new_datacenter

        print("IDMAPPING after init")
        print(json.dumps(id_mappings))

        for id in ['swarm', 'shared', 'system', 'private', 'scheduler', 'none', 'viewonly', 'restrictedcontrol', 'fullcontrol']:
            id_mappings[id] = id 

        print("IDMAPPING after builtins")
        print(json.dumps(id_mappings))

        for role in data['roles']:
            if not role['system_role']:
                id_mappings[role['id']] = create_role(url, session_token, role)

        print("IDMAPPING after roles")
        print(json.dumps(id_mappings))

        for org in data['orgs']:
            if org['name'] != 'docker-datacenter':
                id_mappings[org['id']] = create_org(url, session_token, org['name'])
            for team in org['teams']:
                id_mappings[team['id']] = create_team(url, session_token, org['name'], team['name'])
                set_org_team_sync(url, session_token, org['name'], team['name'], team['sync'])
                    
        print("IDMAPPING after orgs/teams")
        print(json.dumps(id_mappings))

        collections = sorted(data['collections'], key = lambda i: len(i['parent_ids']))
        for collection in collections:
            if collection['id'] not in ['swarm', 'shared', 'system', 'private'] and collection['path'] != "/Shared/Private/{}".format(username):
                parent_id_to_replace = collection['parent_ids'][-1]
                payload = {
                    'label_constraints': collection['label_constraints'], 
                    'legacy_label_key': collection['legacylabelkey'],
                    'legacy_label_value': collection['legacylabelvalue'],
                    'name': collection['name'],
                    'parent_id': id_mappings[parent_id_to_replace],
                }
                id_mappings[collection['id']] = create_collection(url, session_token, payload)
        
        print("IDMAPPING after collections")
        print(json.dumps(id_mappings))

        for grant in data['grants']['grants']:
            if 'kubernetesnamespace' not in grant['objectID']:
                create_grant(
                    url, 
                    session_token, 
                    id_mappings[grant['subjectID']],
                    id_mappings[grant['objectID']],
                    id_mappings[grant['roleID']]
                )
        
    if mode == 'b':
        data = {}
        data['admin_login_id'] = get_user_id(url, session_token, username)
        data['orgs'] = get_orgs(url, session_token)['accounts']
        for org in data['orgs']:
            org['teams'] = get_teams_in_org(url, session_token, org['name'])['teams']
            for team in org['teams']:
                team['sync'] = get_org_team_sync(url, session_token, org['name'], team['name'])
        data['roles'] = get_roles(url, session_token)
        data['collections'] = get_collections(url, session_token)
        data['grants'] = get_grants(url, session_token)      
        with open('/out/backupdata.json', 'w') as outfile:
            json.dump(data, outfile)
