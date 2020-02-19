#!/bin/bash

# A tool that can be used to automate and schedule regular backups of UCP and DTR.
# Run this tool on a UCP controller.
# It will take both UCP and DTR backups sequentially and then save 
# the backups to the pwd of the UCP controller.

# set environment variables
USERNAME="admin"
PASSWORD="fake-password"
UCP_URL="1.1.1.1"
UCP_VERSION="2.1.5"
DTR_URL="2.2.2.2"
DTR_VERSION="2.3.3"
DTR_REPLICA="5007fbad4136"


ucpBackup() {
    # Timeout required to allow user to cancel backup
    echo "Starting UCP backup in 20 seconds."
    echo "This UCP controller will temporarily shut down but an HA UCP will remain up."
    sleep 20

    # Health checking for this UCP controller before backup
    if [ "$(curl -k -s "https://${UCP_URL}/_ping")" != "OK" ]; then
        echo "UCP Controller ${UCP_URL} returned bad health. Exiting backup script."
        exit 1
    fi
    echo "UCP health is OK"

    UCP_BACKUP_NAME="ucp-${UCP_VERSION}-backup-$(date +%F-%R).tar"

    UCP_ID="$(docker run --rm -i --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:"${UCP_VERSION}" id 2> /dev/null)"

    echo "UCP backup starting ..."
    docker run --rm -i --name ucp \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "docker/ucp:${UCP_VERSION}" backup \
        --id "${UCP_ID}" \
        --debug > "${UCP_BACKUP_NAME}"

    if [ ! -s "${UCP_BACKUP_NAME}" ]; then
        echo "Backup was unsucessful. Run UCP backup manually."
        exit 1
    fi

    echo "UCP backup complete and saved as ${UCP_BACKUP_NAME}"
}


dtrBackup() {
    # Timeout required to allow UCP to come backup. UCP was restarted in previous step.
    echo "Starting DTR backup in 30 seconds. DTR will continue running during the backup."
    sleep 30

    # Health checking DTR replica before backup
    if [ "$(curl -k -s "https://${DTR_URL}/health" | jq ".Healthy")" != "true" ]; then
        echo "DTR Replica ${DTR_URL} returned bad health. Exiting backup script."
        exit 1
    fi
    echo "DTR health is OK"

    DTR_BACKUP_NAME="dtr-${DTR_VERSION}-backup-$(date +%F-%R).tar"

    echo "DTR backup starting ..."
    docker run -i --rm docker/dtr:"${DTR_VERSION}" backup \
      --debug \
      --ucp-username "${USERNAME}" \
      --ucp-password "${PASSWORD}" \
      --ucp-insecure-tls \
      --existing-replica-id "${DTR_REPLICA}" \
      --ucp-url "https://${UCP_URL}" > "${DTR_BACKUP_NAME}"

    if [ ! -s "${DTR_BACKUP_NAME}" ]; then
        echo "Backup was unsucessful. Run DTR backup manually."
        exit 1
    fi

    echo "DTR backup complete and saved as ${DTR_BACKUP_NAME}"
}

#Entrypoint for program
echo "----------- Docker EE Backup Tool -----------"
echo ""
echo ""
ucpBackup
dtrBackup
echo "UCP and DTR backups are complete. Remember to test the backups with a UCP & DTR restore from time to time."
