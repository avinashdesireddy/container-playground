
## Install Docker Enterprise Engine

### Linux Nodes

```bash
export DOCKER_URL="https://storebits.docker.com/ee/m/sub-XXXXXXXXXXXXX"

## Install dependencies
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --enable rhel-7-server-extras-rpms
sudo yum-config-manager --enable rhui-rhel-7-server-rhui-extras-rpms

## Configure Docker-ee repository
sudo -E sh -c 'echo "$DOCKERURL/rhel" > /etc/yum/vars/dockerurl'
sudo sh -c 'echo "7" > /etc/yum/vars/dockerosversion'
sudo -E yum-config-manager --add-repo "$DOCKERURL/rhel/docker-ee.repo"
sudo yum -y install docker-ee docker-ee-cli containerd.io

## Enable and Start docker engine
sudo systemctl start docker 
sudo systemctl enable docker
```

**Easy Install Script - DO NOT SHARE THIS WITH CUSTOMERS**
```bash
DOCKER_URL=https://storebits.docker.com/ee/m/sub-XXXXXXXXXXX

curl -fsSL https://s3-us-west-2.amazonaws.com/internal-docker-ee-builds/install.sh | DOCKER_URL=$DOCKER_URL CHANNEL=stable-19.03.5 bash && sudo systemctl enable docker && sudo systemctl start docker
```

Disable selinux
```bash
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

TODO: Add Kernel tuning

### Windows Nodes

```
Install-PackageProvider `
  -Name NuGet `
  -Force;

Install-Module `
  -Name DockerMsftProvider `
  -Force;

Install-Package `
  -Name Docker `
  -ProviderName DockerMsftProvider `
  -Force;

Restart-Computer;
```

TODO: Add OS tuning steps

## Initialize Swarm

```
docker swarm init --default-addr-pool 172.16.0.0/16
```

- TODO: Add Networking info
- TODO: Add address pool calculator

## Installing UCP

```bash
UCP_VERSION=latest
UCP_ADMIN_USER=docker
UCP_ADMIN_PASSWORD=
UCP_DNS=ucp.avinash.dockerps.io

sudo docker container run --rm -it --name ucp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    docker/ucp:${UCP_VERSION} install \
    --host-address $(hostname -i) \
    --admin-username $UCP_ADMIN_USER \
    --admin-password $UCP_ADMIN_PASSWORD \
    --san $UCP_DNS \
    --debug

### Additional options
     --license “$(cat license.lic)”
```
*Note:* If custom certificates are used - The SAN entries provided here are temperory. Just provide one

Uninstall UCP
```bash
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    docker/ucp \
    uninstall-ucp
```

## Custom TLS
Replacing the TLS certificates is done though the UCP web portal, instructions are here: [https://docs.docker.com/ee/ucp/admin/configure/use-your-own-tls-certificates/](https://docs.docker.com/ee/ucp/admin/configure/use-your-own-tls-certificates/)

Obtain free TLS/SSL certificates from letsencrypt - [Instructions](./misc/certs.md)

#### Adding UCP Manager Nodes

To join nodes to the cluster, go to the UCP web interface and navigate to the Nodes page.

1. Log into UCP
2. Goto Shared Resources → Nodes → Select Add Node
3. Click Add Node to add a new node.
4. Select the type of node to add, Linux.
5. Click Manager.
6. Click the copy in the text box
7. SSH into Linux Worker Node
8. Run the copied docker swarm join command on the manager node.

#### Adding UCP Worker Nodes

To join nodes to the cluster, go to the UCP web interface and navigate to the Nodes page.

1. Log into UCP
2. Goto Shared Resources → Nodes → Select Add Node
3. Click Add Node to add a new node.
4. Select the type of node to add, Linu/Windows and follow the instructions.
5. Click Worker.
6. Click the copy in the text box
7. Login to the node
8. Run the copied docker swarm join command on the worker node.

## Installing DTR
1. Copy the certs to the DTR node
2. Source admin user's bundle
   
   *Tip:* It is not necessary to login to DTR nodes to configure DTR.
```bash
DTR_VERSION=latest
DTR_CA=ca.pem
DTR_CERT=cert.pem
DTR_KEY=key.pem
DTR_DNS=dtr.avinash.dockerps.io
UCP_DNS=ucp.avinash.dockerps.io
UCP_CA=ca.pem
UCP_ADMIN_USER=docker
UCP_ADMIN_PASSWORD=
UCP_NODE=
NFS_SHARE="nfs.avinash.dockerps.io/dtr"

## Install command
docker run -it docker/dtr:${DTR_VERSION} install \
    --ucp-url "https://${UCP_DNS}" \
    --ucp-username "${UCP_ADMIN_USER}" \
    --ucp-password "${UCP_ADMIN_PASSWORD}" \
    --ucp-node "${UCP_NODE}" \
    --nfs-storage-url "nfs://${NFS_SHARE}" \
    --dtr-external-url "https://${DTR_DNS}" \
    --ucp-ca "$(cat $UCP_CA)" \
    --dtr-ca "$(cat $DTR_CA)" \
    --dtr-cert "$(cat $DTR_CERT)" \
    --dtr-key "$(cat $DTR_KEY)"
```

3. Join additional replica

```bash
# Change the UCP_NODE
UCP_NODE=

# Get DTR Replica ID
REPLICA_ID=$(curl --request GET --insecure --silent --url "https://${DTR_DNS}/api/v0/meta/settings" -u "${UCP_ADMIN_USER}":"${UCP_ADMIN_PASSWORD}" --header 'Accept: application/json' | jq --raw-output .replicaID)

# Join DTR Node
docker run \
    --rm \
    docker/dtr:${DTR_VERSION} join \
    --existing-replica-id "${REPLICA_ID}" \
    --ucp-url "https://${UCP_DNS}" \
    --ucp-node "${UCP_NODE}" \
    --ucp-username "${UCP_ADMIN_USER}" \
    --ucp-password "${UCP_ADMIN_PASSWORD}" \
    --ucp-ca "$(cat $UCP_CA)"
```