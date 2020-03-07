#!/bin/sh
# Available on hub: docker pull squizzi/populate-dtr:latest
# Script to quickly and easily populate a DTR test environment with some images and tags
# Note: Ensure the DTR is licensed and create on push is enabled before running.

# Usage/help text
usage_text () {
    echo -e "Usage: docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock squizzi/populate-dtr -H <hostname>:<port> -u <username> -p <password>"
    exit 1
}

# Colors
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

while getopts "hu:p:H:" opt; do
  case $opt in
    h)
      usage_text
      ;;
    u)
      DTR_USER="$OPTARG"
      ;;
    p)
      DTR_PASSWORD="$OPTARG"
      ;;
    H)
      DTR_URL="$OPTARG"
      ;;
    \?)
      usage_text
      exit 1
      ;;
    :)
      echo -e "Option -$OPTARG requires an argument." >&2
      exit 1;
      ;;
    esac
done

# Check for docker socket
if [ ! -e "/var/run/docker.sock" ]; then
    echo -e "${RED}Error: Docker not detected, did you forget to mount docker.sock?${NC}"
    exit 1
fi

# Check for DTR_URL
if [ -z "$DTR_URL" ]; then
    echo -e "${CYAN}Option -H requires an argument: a DTR URL is required${NC}"
    exit 1
fi

# Populate commonly used defaults if they aren't already set
if [ -z "DTR_USER" ]; then
    DTR_USER="admin"
    echo -e "${CYAN}Using default username: $DTR_USER${NC}"
fi

if [ -z "DTR_PASSWORD" ]; then
    DTR_PASSWORD="foobarfun"
    echo -e "${CYAN}Using default password: $DTR_PASSWORD${NC}"
fi

# Login
echo -e "${CYAN}Logging into $DTR_URL as $DTR_USER${NC}"
if ! docker login $DTR_URL -u $DTR_USER -p $DTR_PASSWORD > /dev/null 2>&1; then
    echo -e "${RED}Error: Unable to login to $DTR_URL${NC}"
    exit 1
fi

# Pull several different images and some tags from hub
echo -e "${CYAN}Pulling several different images and tags...${NC}"
docker pull nginx
docker pull alpine
docker pull ubuntu
docker pull fedora:26
docker pull fedora:27
docker pull fedora
docker pull redis

# Tag and push the pulled images with the defined user
echo -e "${CYAN}Pushing the pulled images as $DTR_USER...${NC}"
IMAGES=$(docker images -a | egrep -vi 'docker|repository|populate' | awk '{print $1":"$2}')
for image in $IMAGES
do
    docker tag $image $DTR_URL/$DTR_USER/$image
done

IMAGES_NEW=$(docker images -a | grep $DTR_URL | awk '{print $1}')
for image in $IMAGES_NEW
do
    docker push $image
done
