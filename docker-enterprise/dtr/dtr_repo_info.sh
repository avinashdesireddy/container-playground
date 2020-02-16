#!/bin/bash

function status (){
  echo " Usage: $0 <repo-file-name>"
  exit 1
}

if [ -z "$1" ]
  then
    status
fi
## Capture DTR Info
[ -z "$DTR_HOSTNAME" ] && read -p "Enter the DTR hostname and press [ENTER]:" DTR_HOSTNAME
[ -z "$DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" DTR_USER
[ -z "$DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" DTR_PASSWORD
echo "***************************************\\n"

RESULTS_FILE=$1
: > $RESULTS_FILE

## Extract repositories info
repos=$(curl -ks -u ${DTR_USER}:${DTR_PASSWORD} -X GET "https://${DTR_HOSTNAME}/api/v0/repositories?pageSize=100000&count=true" -H "accept: application/json" | jq -r -c .repositories)
repo_num=$(echo $repos | jq 'length')
repo_list=$(echo "${repos}" | jq -c -r '.[]')
# # Loop through repos to get total tags
tags=0
while IFS= read -r row ; do
    namespace=$(echo "$row" | jq -r .namespace)
    reponame=$(echo "$row" | jq -r .name)
    tag_list=$(curl -ksLS -u ${DTR_USER}:${DTR_PASSWORD} -X GET "https://$DTR_HOSTNAME/api/v0/repositories/${namespace}/${reponame}/tags?pageSize=10000000")
    tag_count=$(echo "$tag_list" | jq 'length' )
    echo "Org: ${namespace}, Repo: ${reponame}, Tags: ${tag_count}"
    tags=$(($tags + $tag_count))
done <<< "$repo_list"
echo "=========================================\\n"
echo "Total Repos: ${repo_num}"
echo "Total Tags: ${tags}"

echo "Saving results to ${RESULTS_FILE}"
echo $repos > ${RESULTS_FILE}
