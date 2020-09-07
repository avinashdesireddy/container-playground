#!/usr/bin/env bash

# set -x


function error_exit {
  echo "$1" >&2   ## Send message to stderr. Exclude >&2 if you don't want it that way.
  exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

[[ -z $UCP_URL ]] && error_exit "you must specify a UCP URL to backup from"
[[ -z $UCP_USER ]] && error_exit "you must specify a UCP User with admin privileges"
[[ ! -f /run/secrets/password ]] && error_exit "you must mount a docker secret with your admin password in /run/secrets/password; see 'docker secrets' usage."

UCP_PASSWORD="$(cat /run/secrets/password)"

DTR_VERSION=$(docker inspect $(docker ps -aq --filter=name=dtr-registry | head -n 1) | jq -r '.[].Config.Env[]' | grep DTR_VERSION | cut -d "=" -f 2 )
DTR_REPLICA_ID=$(docker inspect $(docker ps -aq --filter=name=dtr-registry | head -n 1) | jq -r '.[].Config.Env[]' | grep DTR_REPLICA_ID | cut -d "=" -f 2)

echo "calling backup against ${UCP_URL} with replica ${DTR_REPLICA_ID} and dtr:${DTR_VERSION} image..."

docker run --rm \
  --env UCP_PASSWORD \
  docker/dtr:${DTR_VERSION} backup \
  --debug \
  --ucp-url ${UCP_URL} \
  --ucp-insecure-tls \
  --ucp-username ${UCP_USER} \
  --ucp-password ${UCP_PASSWORD} \
  --existing-replica-id ${DTR_REPLICA_ID} > "/backup/$(date --iso-8601)-$(hostname)-dtr-backup.tar"
