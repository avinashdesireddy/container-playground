#!/bin/bash
## Author: steven.showers@docker.com
## A simple script for testing connectivity between worker nodes and managers on standard UDP and TCP ports. 
## See: https://docs.docker.com/ee/ucp/admin/install/system-requirements/#ports-used
## The result is a log file in `/tmp` named `ee-ports-from-hosta-to-hostb-<date>.log`

shellcheck(){ ps auxww | grep $$ | grep -wq "bash"; echo $?; }

if [ $(shellcheck) = 1 ]; then
   echo "This script must be executed with BASH."
   echo "Exiting..."
   exit 1
fi


HOST=$1
TYPE=$(echo $2 | tr '[:upper:]' '[:lower:]')
NC=$(which nc 2> /dev/null 1> /dev/null; echo $?)
FILE=/tmp/ee-ports-from-$(hostname -s)-to-$HOST-$(date +%s%z).log

MANAGER_TCP_PORTS='
179
2376
2377
6443
6444
7946
9099
10250
12376
12378
12379
12380
12381
12382
12383
12384
12385
12386
12387
12388'

MANAGER_UDP_PORTS='
4789
7946'

WORKER_TCP_PORTS='
179
12376
6444
7946
9099
10250
12376
12378'

WORKER_UDP_PORTS='
7946'

if [ "$NC" = "1" ]; then
   echo "You must install netcat: e.g. yum install nc -y"
   exit 1
elif [ "$HOST" = "" -o "$TYPE" = "" -a "$NC" = "1" ]; then
   echo "You must install netcat: e.g. yum install nc -y"
   echo "Syntax: ee-ports.sh <node-ip-address> <worker-OR-manager>"
   exit 1
elif [ "$HOST" = "" -o "$TYPE" = "" -a "$NC" = "0" ]; then
   echo "Syntax: ee-ports.sh <node-ip-address> <worker-OR-manager>"
   exit 1
else
   if [ "$TYPE" = "manager" ]; then
      echo -ne "\n${HOST} is a ${TYPE}\n" | tee -a ${FILE}
      sleep 2
      for i in $MANAGER_TCP_PORTS; do echo -ne "\n***TESTING $(hostname -s) to $HOST on TCP port $i***"; nc -i1 -w3 -v $HOST $i;  done 2>&1 | tee -a ${FILE}
      for i in $MANAGER_UDP_PORTS; do echo -ne "\n***TESTING $(hostname -s) to $HOST on UDP port $i***"; nc -u -vz $HOST $i;  done 2>&1 | tee -a ${FILE}
      echo -ne "\nPlease attach this file to the case: ${FILE}\n"
   elif [ "$TYPE" = "worker" ]; then
      echo -ne "\n${HOST} is a ${TYPE}\n" | tee -a ${FILE}
      sleep 2
      for i in $WORKER_TCP_PORTS; do echo -ne "\n***TESTING $(hostname -s) to $HOST on TCP port $i***"; nc -i1 -w3 -v $HOST $i;  done 2>&1 | tee -a ${FILE}
      for i in $WORKER_UDP_PORTS; do echo -ne "\n***TESTING $(hostname -s) to $HOST on UDP port $i***"; nc -u -vz $HOST $i;  done 2>&1 | tee -a ${FILE}
      echo -ne "\nPlease attach this file to the case: ${FILE}\n"
   fi
fi
