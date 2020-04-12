#!/bin/bash

## Capture DTR Info
[ -z "$DTR_HOSTNAME" ] && read -p "Enter the DTR hostname and press [ENTER]:" DTR_HOSTNAME
[ -z "$DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" DTR_USER
[ -z "$DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" DTR_PASSWORD
echo "***************************************\\n"

REPOSITORIES_FILE=repositories.json

TOKEN=$(curl -kLsS -u ${DTR_USER}:${DTR_PASSWORD} "https://${DTR_HOSTNAME}/auth/token" | jq -r '.token')
CURLOPTS=(-kLsS -H 'accept: application/json' -H 'content-type: application/json' -H "Authorization: Bearer ${TOKEN}")

## Read repositories file
repo_list=$(cat ${REPOSITORIES_FILE} | jq -c -r '.[]') 

# Loop through repositories
while IFS= read -r row ; do
    namespace=$(echo "$row" | jq -r .namespace)
    reponame=$(echo "$row" | jq -r .name)
    repodetails=$(echo "$row" | jq 'del(.id)')

    # TODO: Check if repository exists
    # Create a repository with the settings read from repo_list
    curl "${CURLOPTS[@]}" -X POST -d "$repodetails" https://${DTR_HOSTNAME}/api/v0/repositories/${namespace}
    echo "Created ==> Org: ${namespace}, Repo: ${reponame}"
done <<< "$repo_list"
echo "=========================================\\n"

