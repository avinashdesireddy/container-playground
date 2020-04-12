#!/bin/bash

function status (){
  echo " Usage: $0 <repo-file-name> <public|private|reset>"
  exit 2
}

if [ -z "$1" ] || [ -z "$2" ]
  then
    status
fi

if [[ "$2" =~ ^(public|private|reset)$ ]]; then
    echo "Changing visibility"
else
    echo "Invalid visibility $2"
    status
fi

## Capture DTR Info
[ -z "$DTR_HOSTNAME" ] && read -p "Enter the DTR hostname and press [ENTER]:" DTR_HOSTNAME
[ -z "$DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" DTR_USER
[ -z "$DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" DTR_PASSWORD
echo "***************************************\\n"

REPOSITORIES_FILE=$1

TOKEN=$(curl -kLsS -u ${DTR_USER}:${DTR_PASSWORD} "https://${DTR_HOSTNAME}/auth/token" | jq -r '.token')
CURLOPTS=(-kLsS -H 'accept: application/json' -H 'content-type: application/json' -H "Authorization: Bearer ${TOKEN}")

## Read repositories file
repo_list=$(cat ${REPOSITORIES_FILE} | jq -c -r '.[]') 

# Loop through repositories
while IFS= read -r row ; do
    namespace=$(echo "$row" | jq -r .namespace)
    reponame=$(echo "$row" | jq -r .name)
    if [[ "$2" =~ ^(public|private)$ ]]; then
        repodetails=$(echo {\"visibility\": \"$2\"})
    else
        visibility=$(echo "$row" | jq -r .visibility)
        repodetails=$(echo {\"visibility\": \"$visibility\"})
    fi

    # TODO: Check if namespace exists
    
    # TODO: Check if repository exists

    # Create a repository with the settings read from repo_list
    response=$(curl "${CURLOPTS[@]}" -X PATCH -d "$repodetails" https://${DTR_HOSTNAME}/api/v0/repositories/${namespace}/${reponame})
    visibility=$(echo $response | jq -r .visibility)
    echo "Org: ${namespace}, Repo: ${reponame}, Visibility: ${visibility}"
done <<< "$repo_list"
echo "=========================================\\n"

