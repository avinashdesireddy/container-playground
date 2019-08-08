#/bin/bash

##########################################
### Author: Avinash Desireddy
### Github Handle: avinashdesireddy
##########################################

echo ""
echo -e "DON'T RUN THIS AS SCRIPT.\nSource this file using the command \n\t$ source <path-to-file>/ucp-bundle.sh OR $ eval \"\$(<ucp-bundle.sh)\""
echo ""
[ -z "$UCP_FQDN" ] && read -p "UCP FQDN:" UCP_FQDN
[ -z "$DUSER" ] && read -p "Username:" DUSER
[ -z "$PASSWORD" ] && read -s -p "Password:" PASSWORD

echo "Authenticating with UCP: "
# use your UCP username and password to acquire a UCP API auth token
data=$(echo {\"username\": \"$DUSER\" ,\"password\": \"$PASSWORD\" })
AUTHTOKEN=$(curl -sk -d "${data}" https://${UCP_FQDN}/auth/login | python -c "import sys, json; print json.load(sys.stdin)['auth_token']")

# make your life easy by creating a curl alias that automatically uses your auth token:
alias ucp-api='curl -sk -H "Authorization: Bearer $AUTHTOKEN"'

# download and initialize the client bundle authorizing action based on the permissions of the user who fetched the auth token above
echo "Obtaining clientbundle"
mkdir -p ~/.docker/${UCP_FQDN}/${DUSER}; cd ~/.docker/${UCP_FQDN}/${DUSER};
ucp-api https://${UCP_FQDN}/api/clientbundle -o bundle.zip
unzip -oq bundle.zip
eval "$(<env.sh)"
cd ~-

echo "Successful"
unset DUSER
unset PASSWORD

# all docker and kubectl commands are now issued to your UCP cluster, instead of the local node. To undo this, run:
# unset DOCKER_TLS_VERIFY COMPOSE_TLS_VERSION DOCKER_CERT_PATH DOCKER_HOST
