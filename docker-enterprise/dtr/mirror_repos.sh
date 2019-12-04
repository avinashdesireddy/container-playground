#!/bin/bash

## Capture DTR Info
[ -z "$DTR_HOSTNAME" ] && read -p "Enter the DTR hostname and press [ENTER]:" DTR_HOSTNAME
[ -z "$DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" DTR_USER
[ -z "$DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" DTR_PASSWORD
echo "********* REMOTE DTR CONFIG ***********\\n"
[ -z "$REMOTE_DTR_HOSTNAME" ] && read -p "Enter the REMOTE DTR hostname and press [ENTER]:" REMOTE_DTR_HOSTNAME
[ -z "$REMOTE_DTR_USER" ] && read -p "Enter the DTR username and press [ENTER]:" REMOTE_DTR_USER
[ -z "$REMOTE_DTR_PASSWORD" ] && read -s -p "Enter the DTR token or password and press [ENTER]:" REMOTE_DTR_PASSWORD

echo ""
echo "***************************************\\n"

REMOTE_USER=${REMOTE_DTR_USER}
REMOTE_TOKEN=${REMOTE_DTR_PASSWORD}
REMOTE_URL="https://${REMOTE_DTR_HOSTNAME}"

REPOSITORIES_FILE=repositories.json

TOKEN=$(curl -kLsS -u ${DTR_USER}:${DTR_PASSWORD} "https://${DTR_HOSTNAME}/auth/token" | jq -r '.token')
CURLOPTS=(-kLsS -H 'accept: application/json' -H 'content-type: application/json' -H "Authorization: Bearer ${TOKEN}")

## Read repositories file
repo_list=$(cat ${REPOSITORIES_FILE} | jq -c -r '.[]') 


# Loop through repositories
while IFS= read -r row ; do
    namespace=$(echo "$row" | jq -r .namespace)
    reponame=$(echo "$row" | jq -r .name)

    ## Get existing mirroring policies
    pollMirroringPolicies=$(curl "${CURLOPTS[@]}" -X GET \
        "https://${DTR_HOSTNAME}/api/v0/repositories/${namespace}/${reponame}/pollMirroringPolicies")

    num_mirrors=$(echo $pollMirroringPolicies | jq 'length')
    if [ "$num_mirrors" -eq "0" ]; then
        ## Post data for mirror
        mirrordata=$(echo { \"rules\": [], \"username\": \"${REMOTE_USER}\", \"password\": \"${REMOTE_TOKEN}\", \"localRepository\": \"${namespace}/${reponame}\", \"remoteHost\": \"${REMOTE_URL}\", \"remoteRepository\": \"${namespace}/${reponame}\", \"remoteCA\": \"\", \"skipTLSVerification\": true, \"tagTemplate\": \"%n\", \"enabled\": false })

        response=$(curl "${CURLOPTS[@]}" -X POST -d "$mirrordata" \
            "https://${DTR_HOSTNAME}/api/v0/repositories/${namespace}/${reponame}/pollMirroringPolicies?initialEvaluation=true")

        echo $response
        echo "Configured mirror on repo ${namespace}/${reponame}"
    else
        echo "Mirror already configured on ${namespace}/${reponame}"
    fi

done <<< "$repo_list"
echo "=========================================\\n"

