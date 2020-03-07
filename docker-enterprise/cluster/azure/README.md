
export CLUSTER_SECRETS_FILE=~/.secrets/docker-azure-cred.sh

docker cluster --log-level debug create --file cluster.yml --name odot-dee-centos
