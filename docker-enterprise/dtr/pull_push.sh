#!/bin/bash

## Capture DTR Info
[ -z "$DTR_HOSTNAME" ] && read -p "Enter the DTR hostname and press [ENTER]:" DTR_HOSTNAME
[ -z "$DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" DTR_USER
[ -z "$DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" DTR_PASSWORD
echo ""
echo "***************************************\\n"

[ -z "$REMOTE_DTR_HOSTNAME" ] && read -p "Enter REMOTE DTR hostname and press [ENTER]:" REMOTE_DTR_HOSTNAME

REPOSITORIES_FILE=repo.txt

TOKEN=$(curl -kLsS -u ${DTR_USER}:${DTR_PASSWORD} "https://${DTR_HOSTNAME}/auth/token" | jq -r '.token')
CURLOPTS=(-kLsS -H 'accept: application/json' -H 'content-type: application/json' -H "Authorization: Bearer ${TOKEN}")

## Read repositories file
repo_list=$(cat ${REPOSITORIES_FILE} | jq -c -r '.[]') 

# Loop through repositories
grep -i "Pending" $REPOSITORIES_FILE | while read -r line ; do
    reponame=$(echo "$line" | cut -f2 -d":" | cut -f1 -d"," | xargs)
    tags=$(curl -ksLS -u ${DTR_USER}:${DTR_PASSWORD} -X GET "https://$DTR_HOSTNAME/api/v0/repositories/${reponame}/tags?pageSize=100000000")

    tags_list=$(echo $tags | jq -c -r '.[]')
    while IFS= read -r tag ; do
        tagname=$(echo "$tag" | jq -r .name)
        docker pull ${DTR_HOSTNAME}/${reponame}:${tagname}
        docker tag ${DTR_HOSTNAME}/${reponame}:${tagname} ${REMOTE_DTR_HOSTNAME}/${reponame}:${tagname}
        docker push ${REMOTE_DTR_HOSTNAME}/${reponame}:${tagname}
    done <<< "$tags_list"

    while IFS= read -r tag ; do
        tagname=$(echo "$tag" | jq -r .name)
        docker image rm ${DTR_HOSTNAME}/${reponame}:${tagname}
        docker image rm ${REMOTE_DTR_HOSTNAME}/${reponame}:${tagname}
    done <<< "$tags_list"
    echo "Complete: ${reponame}"
done
echo "=========================================\\n"

