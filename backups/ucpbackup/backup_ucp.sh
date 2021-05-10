#!/usr/bin/env bash

# set -x
function error_exit {
  echo "$1" >&2   ## Send message to stderr. Exclude >&2 if you don't want it that way.
  exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

[[ -z $UCP_URL ]] && error_exit "you must specify a UCP URL to backup from"

echo "Performing UCP backup against cluster at $UCP_URL"
docker container run --log-driver none --rm -i \
  --name ucp-backup \
  -v /var/run/docker.sock:/var/run/docker.sock \
  mirantis/ucp:${UCP_VERSION} \
  backup \
  --no-passphrase \
  --debug > "/backup/$(date --iso-8601)-$(hostname)-mke-backup.tar"

