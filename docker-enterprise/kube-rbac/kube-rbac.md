Docker UCP, Kubernetes Role Based Access Control
===

###### tags: `kubernetes-rbac`

In a Real environment, we need to have
- Multiple users with different properties, establishing a proper authentication mechanism
- Full control over the operations each user or group of users can execute
- Full control over which operations each process inside a pod can execute
- Limit the visibility of certain resources of namespaces

**RBAC is a key element for providing all these essential features**

### Key elements of RBAC
* *Subjects* - Users and processes
* *Resources* - Objects on which access should be restricted
* *Verbs* - Set of operations that can be executed. Often referred as actions.
* *Roles* - Connect API Resources and Verbs.
* *RoleBinding* - Connect Roles with Subjects.

## Kubernetes RBAC
### Namespaces 
- Namespace is a virtual cluster inside a kubernetes cluster
- Multiple namespaces isolate with each other allowing to create different partitions of the cluster.
- 3 Namespaces (default, kube-system, kube-public)

### Subjects
- Set of Users and processes that want to access the Kubernetes API
- In Docker Enterprise Edition, UCP is used to manage user and group.
- Orgs, Teams(Groups), Users and Service accounts
- Service accounts are used when apps may need access to Kube API (ex: logging, monitoring, etc)
- Service accounts funtion like 'users' in the same RBAC model

### Resources
- The set of Kubernetes API Objects are available in the Cluster
- Example includes - Pods, Deployments, Services, Nodes, PersistentVolumes, etc.

### Verbs
- Set of Operations that can be executed to the resources above
- get, watch, create, delete, etc.
- All of them are CURD operations.

![](https://i.imgur.com/gGeROgm.png)

### Roles
- Connects API Resources and Verbs
- Reused for different subjects
- Binded to one namespace
- `ClusterRoles` is used if we want to apply role cluster-wide.
- Custom roles are supported

### RoleBindings / Role Grants
- Connects roles with Subjects
- For cluster-level, `ClusterRoleBinding` is used.

![](https://i.imgur.com/LHXDTmJ.png)

## Example Scenario
Creating an Org, Team (with LDAP sync)
- Create org `whalecorp`
- Create teams `marketing`, `accounting`
- Create Namespaces `marketing-ns`, `accounting-ns`
- `marketing` belongs to `marketing-ns` namespace
- `accounting` belongs to `accounting-ns` namespace
- `marketing` and `accounting` defined with Role and RoleBinding
- User `KRBalke` from `marketing` created busybox pod in `marketing-ns` namespace
- User `JKDavid` from `accounting` created busybox pod in `accounting-ns` namespace
- `KRBalke` tried to access busybox pod in `accounting-ns` namespace Access Denied (Valid Use case)
- `JKDavid` tried to access busybox pod in `marketing-ns` namespace Access Denied (Valid Use case)
- `KRBalke` can query pods in `marketing-ns` namespace (Valid Use case)
- `JKDavid` can query pod in `accounting-ns` namespace (Valid Use case)

![](https://i.imgur.com/r0TWija.png)

## Steps:
#### 1. Authentication
```
UCP_URL=ucp.avinash.dockerps.io
DOCKERUSER=docker
PASSWORD=

data=$(echo "{\"username\": \"$DOCKERUSER\" ,\"password\": \"$PASSWORD\" }")
AUTH_TOKEN=$(curl -sk -d "${data}" https://${UCP_URL}/auth/login | python -c "import sys, json; print json.load(sys.stdin)['auth_token']")

```

#### 2. Create Teams
```
ORG_NAME=
TEAM_NAME=
TEAM_DESCRIPTION=

curl -k -X POST "https://${UCP_URL}/accounts/${ORG_NAME}/teams" -H "accept: application/json" -H  "Authorization: Bearer ${AUTH_TOKEN}" -H "content-type: application/json" -d "{ \"description\": \"${TEAM_DESCRIPTION}\", \"name\": \"${TEAM_NAME}\"}"
```

List Orgs
```
curl -kX GET "https://${UCP_URL}/accounts/?filter=orgs" -H  "accept: application/json" -H  "Authorization: Bearer ${AUTH_TOKEN}"
```
#### 3. Map LDAP config with AD Group
```
GROUP_DN="cn=marketing,ou=groups,ou=demo accounts,dc=avinash,dc=com"
GROUP_MEMBERATTR=member

curl -k -X PUT "https://${UCP_URL}/accounts/${ORG_NAME}/teams/${TEAM_NAME}/memberSyncConfig" -H  "accept: application/json" -H  "Authorization: Bearer ${AUTH_TOKEN}" -H  "content-type: application/json" -d "{  \"enableSync\": true,  \"groupDN\": \"${GROUP_DN}\",  \"groupMemberAttr\": \"${GROUP_MEMBERATTR}\",  \"searchBaseDN\": \"\",  \"searchFilter\": \"\",  \"searchScopeSubtree\": false,  \"selectGroupMembers\": true}"
```
Get LDAP member config
```
curl -k -X GET "https://${UCP_URL}/accounts/${ORG_NAME}/teams/${TEAM_NAME}/memberSyncConfig" -H "accept: application/json" -H "Authorization: Bearer ${AUTH_TOKEN}"
```

#### 4. Create Namespaces
```
kubectl create ns marketing-ns
kubectl create ns accouting-ns
```

#### 5. Create Roles
Create `role-marketing.yaml`
```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: marketing-ns
  name: marketing-role
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["list", "get", "watch", "create", "update", "patch", "delete"]
```

Create `role-accounting.yaml`
```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: accounting-ns
  name: accounting-role
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["list", "get", "watch", "create", "update", "patch", "delete"]
```

#### 6. Create `marketing` Rolebinding
UI Based approach

#### 7. Create `accounting` Rolebinding

a. Capture Org ID and Team ID using UCP API.
b. Replace the subject name with respect to the following
    - *Org* - org:<orgid>
    - *Group* - team:<orgid>:<teamid>
    - *User* - Username or userid

    curl -kX GET "https://${UCP_URL}/accounts/${ORG_NAME}/teams/${TEAM_NAME}" -H  "accept: application/json" -H  "Authorization: Bearer ${AUTH_TOKEN}"

Create `rolebinding-accounting.yaml`
```
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: accounting-role-binding
  namespace: accounting-ns
subjects:
- kind: Group
  name: team:e3e5c4a3-0559-4e53-8084-4ad1fef4a35d:b60372de-63c1-424d-8c0d-7b3bd317fc75
  apiGroup: "rbac.authorization.k8s.io"
roleRef:
  kind: Role
  name: accounting-role
  apiGroup: "rbac.authorization.k8s.io"
```

#### 8. Verify Roles and RoleBindings
kubectl get roles -n marketing-ns
kubectl get roles -n accounting-ns
kubectl get rolebinding -n marketing-ns
kubectl get rolebinding -n accounting-ns
kubectl describe rolebinding accounting-role-binding -n accounting-ns

```
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - image: busybox
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
    name: busybox
  restartPolicy: Always
```

Obtain Client bundle for both the Users

Launch busybox pod on both nameservices
```
kubectl create -f busybox.yaml -n marketing-ns
kubectl create -f busybox.yaml -n accounting-ns
```

List pods in the same namespace and in different namespace
```
kubectl get pods -n accounting-ns
kubectl get pods -n marketing-ns

kubectl auth can-i create deployments --namespace accounting-ns
kubectl auth can-i create deployments --namespace marketing-ns
```

Using CURL with YAML
```
curl -kX POST -d "https://${UCP_URL}/apis/rbac.authorization.k8s.io/v1/namespaces/accounting-ns/rolebindings/"  -H  "accept: application/json" -H  "Authorization: Bearer ${AUTH_TOKEN}"
```


# Automation Framework
- Define UCP & AD info
- Obtain Client bundle
- Use API call to Create Team with LDAP Group sync enabled
- Use Kube API commands to creat e role and rolebindings



