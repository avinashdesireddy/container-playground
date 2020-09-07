#!/bin/bash

# A tool that can be used to automate and schedule regular backups of UCP and DTR.
# Run this tool on a UCP controller.
# It will take both UCP and DTR backups sequentially and then save
# the backups to the pwd of the UCP controller.

# set environment variables
USERNAME="docker"
PASSWORD="Dockeradmin!"
UCP_URL="ucp.avinash.demo-azure-cs.mirantis.com"
UCP_VERSION="3.2.6"
DTR_URL="dtr.avinash.demo-azure-cs.mirantis.com"
DTR_VERSION="2.7.6"
DTR_REPLICA="c526ced27fce"

BACKUP_BASE_LOCATION="/backup"
ucp-backup() {
    echo "----------- Docker EE Backup Tool -----------"
    echo ""
    echo ""

    # Health checking for this UCP controller before backup
    UCP_HEALTH=$(curl -k -s "https://${UCP_URL}/_ping")
    if [ "${UCP_HEALTH}" != "OK" ]; then
        echo "UCP Controller ${UCP_URL} returned bad health. Exiting backup script."
        exit 1
    fi
    echo "UCP health is OK"
    UCP_VERSION=

    UCP_BACKUP_NAME=${BACKUP_BASE_LOCATION}/"ucp-${UCP_VERSION}-backup-$(date +"%Y%m%d_%H%M%S").tar"

    echo "UCP backup starting ..."
    docker run --rm -i --name ucp \
        --log-driver none \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "docker/ucp:${UCP_VERSION}" backup \
        --no-passphrase > "$UCP_BACKUP_NAME"

    if [ $(/bin/ls -ls $UCP_BACKUP_NAME | awk '{print $6}' | bc) == 0 ]; then
        echo "Backup was unsucessful. Run UCP backup manually."
        exit 1
    fi

    echo "UCP backup complete and saved as $UCP_BACKUP_NAME"
}

dtr-backup() {
    echo "Starting DTR backup. DTR will continue running during the backup."

    # Health checking DTR replica before backup
    DTR_HEALTH=$(curl -k -s "https://${DTR_URL}/health" | python -c "import sys, json; print json.load(sys.stdin)['Healthy']")
    if [ "${DTR_HEALTH}" != "True" ]; then
        echo "DTR Replica ${DTR_URL} returned bad health. Exiting backup script."
        exit 1
    fi
    echo "DTR health is OK"

    DTR_BACKUP_NAME=${BACKUP_BASE_LOCATION}/"dtr-${DTR_VERSION}-backup-$(date +"%Y%m%d_%H%M%S").tar"

    echo "DTR backup starting ..."
### Insert DTR backup command

    docker run --log-driver none -i --rm \
        "docker/dtr:${DTR_VERSION}" backup \
        --ucp-url "https://${UCP_URL}" \
        --ucp-insecure-tls \
        --ucp-username ${USERNAME} \
        --ucp-password "${PASSWORD}" \
        --existing-replica-id "${DTR_REPLICA}" --debug > "$DTR_BACKUP_NAME"

    if [ $(/bin/ls -ls $DTR_BACKUP_NAME | awk '{print $6}' | bc) == 0 ]; then
        echo "Backup was unsucessful. Run DTR backup manually."
        exit 1
    fi

    echo "DTR backup complete and saved as $DTR_BACKUP_NAME"
}

#Entrypoint for program
ucp-backup
dtr-backup
echo "UCP and DTR backups are complete. Remember to test the backups with a UCP & DTR restore from time to time."
echo "Removing older files"
find ${BACKUP_BASE_LOCATION}/ -mindepth 1 -mtime +7 -delete