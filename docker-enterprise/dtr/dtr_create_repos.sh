#!/bin/bash

## Capture DTR Info
echo -n "Enter your DTR hostname and press [ENTER]: "
read DTR_HOSTNAME
echo -n "Enter DTR admin username and press [ENTER]: "
read DTR_USER
echo -n "Enter DTR  token or password and press [ENTER]: "
read DTR_PASSWORD
echo "***************************************\\n"

TOKEN=$(curl -kLsS -u ${DTR_USER}:${DTR_PASSWORD} "https://${DTR_HOSTNAME}/auth/token" | jq -r '.token')
CURLOPTS=(-kLsS -H 'accept: application/json' -H 'content-type: application/json' -H "Authorization: Bearer ${TOKEN}")

#set -x
## Read repositories file
repo_list=$(cat repositories.json | jq -c -r '.[]') 

# Loop through repositories
while IFS= read -r row ; do
    namespace=$(echo "$row" | jq -r .namespace)
    reponame=$(echo "$row" | jq -r .name)
    repodetails=$(echo "$row" | jq 'del(.id)')
    echo $repodetails | jq
    # Create a repository with the settings read from repo_list
    curl "${CURLOPTS[@]}" -X POST -d "$repodetails" https://${DTR_HOSTNAME}/api/v0/repositories/${namespace}
    echo "Created ==> Org: ${namespace}, Repo: ${reponame}"
done <<< "$repo_list"
echo "=========================================\\n"

