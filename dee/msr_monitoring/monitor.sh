#!/bin/bash

#############################
# Parameter Validation

function usage {
	echo "Usage: ./monitor.sh <testkit-cluster-name> <start | stop>"
	exit 1
}

if [ "$#" -ne 2 ]; then
	usage
fi

if [[ "$2" != "start" && "$2" != "stop" ]]; then
	usage
fi

#############################

#############################
# Global Configs

CLUSTER_NAME=$1
CMD=$2
CADVISOR_PORT=8080
NODE_EXPORTER_PORT=9100
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
PROMETHEUS_CFG_FILE="prometheus.yml"

#############################


#############################
# Functions

function start_monitoring_containers {
	stop_monitoring_containers $1 $2

	echo "Starting cAdvisor and Prometheus Node-Exporter on Node: $1"
	DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$2:2376 DOCKER_TLS_VERIFY=1 docker run -d -p ${CADVISOR_PORT}:8080 --name cadvisor -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro google/cadvisor:latest

	DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$2:2376 DOCKER_TLS_VERIFY=1 docker run -d -p ${NODE_EXPORTER_PORT}:9100 --net="host" --pid="host" -v "/:/host:ro,rslave" --name prometheus_node_exporter prom/node-exporter:latest --path.rootfs=/host
}

function stop_monitoring_containers {
	hostname=$1
	external_ip=$2
	echo "Cleaning up cAdvisor and Prometheus Node-Exporter on Node: $1"
	
	stop_remote_container $hostname $external_ip cadvisor
	stop_remote_container $hostname $external_ip prometheus_node_exporter
	
	remove_remote_container $hostname $external_ip cadvisor
	remove_remote_container $hostname $external_ip prometheus_node_exporter
}

function stop_remote_container {
	hostname=$1
	external_ip=$2
	container_name=$3
	if [ "$(DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$external_ip:2376 DOCKER_TLS_VERIFY=1 docker ps -q -f name=$container_name)" ]; then
		echo "Stopping container $container_name on $hostname..."
		DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$external_ip:2376 DOCKER_TLS_VERIFY=1 docker kill $container_name
	fi
	
	sleep 3
}

function remove_remote_container {
	hostname=$1
	external_ip=$2
	container_name=$3
	if [ "$(DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$external_ip:2376 DOCKER_TLS_VERIFY=1 docker ps -aq -f name=$container_name)" ]; then
		DOCKER_CERT_PATH=~/.testkit/certs DOCKER_HOST=tcp://$external_ip:2376 DOCKER_TLS_VERIFY=1 docker rm $container_name
	fi
}

function write_prometheus_config_header {
	echo "global:" > ${PROMETHEUS_CFG_FILE}
	echo "  scrape_interval:     120s" >> ${PROMETHEUS_CFG_FILE}
	echo "  evaluation_interval: 120s" >> ${PROMETHEUS_CFG_FILE}
	echo "  external_labels:" >> ${PROMETHEUS_CFG_FILE}
	echo "    monitor: 'my-project'" >> ${PROMETHEUS_CFG_FILE}
	echo "scrape_configs:" >> ${PROMETHEUS_CFG_FILE}
	echo "  - job_name: 'node'" >> ${PROMETHEUS_CFG_FILE}
	echo "    scrape_interval: 5s" >> ${PROMETHEUS_CFG_FILE}
	echo "    static_configs:" >> ${PROMETHEUS_CFG_FILE}
}

function write_prometheus_config_node_entry {
	hostname=$1
	prom_targets=$2
	echo "      - targets: [$prom_targets]" >> ${PROMETHEUS_CFG_FILE}
	echo "        labels:" >> ${PROMETHEUS_CFG_FILE}
        echo "          node: '$hostname'" >> ${PROMETHEUS_CFG_FILE}
}

function start_prometheus {
	stop_prometheus

	# Bring up prometheus with config just created
	docker volume create prometheus_config
	docker volume create prometheus_data
	docker run -d -p ${PROMETHEUS_PORT}:9090 --name prometheus -v ${PWD}/${PROMETHEUS_CFG_FILE}:/etc/prometheus/prometheus.yml:ro -v prometheus_config:/etc/prometheus/ -v prometheus_data:/prometheus prom/prometheus:latest
}

function stop_prometheus {
	docker kill prometheus
	docker rm prometheus
	docker volume rm prometheus_config
	docker volume rm prometheus_data
}

function start_grafana {
	stop_grafana
	# Bring up grafana
	docker volume create grafana_data
	docker run -d -p ${GRAFANA_PORT}:3000 --name grafana -e GF_SECURITY_ADMIN_PASSWORD=admin -v grafana_data:/var/lib/grafana grafana/grafana:latest


	sleep 3
	# Add Prometheus Datasource
	echo "Creating Prometheus datasource in Grafana"
	curl -k -X POST --url "localhost:3000/api/datasources" -u admin:admin -d "{\"name\":\"${CLUSTER_NAME}\", \"type\":\"prometheus\", \"url\":\"http://localhost:9090\",\"access\":\"direct\",\"basicAuth\":false}" -H "Content-type:application/json"
}

function stop_grafana {
	docker kill grafana
	docker rm grafana
	docker volume rm grafana_data
}
#############################


#############################
# Entrypoint

output=$(testkit machine ls | grep "$CLUSTER_NAME")

# Write beginning of Prometheus Config
write_prometheus_config_header

IFS=$'\n'       # make newlines the only separator
for entry in $output;
do
	hostname=$(echo $entry | awk '{print $2}')
	external_ip=$(echo $entry | awk '{print $4}')
	if [ "$CMD" == "start" ]
	then
		start_monitoring_containers $hostname $external_ip
	elif [ "$CMD" == "stop" ]
	then
		stop_monitoring_containers $hostname $external_ip
	fi
	targets="'$external_ip:${CADVISOR_PORT}', '$external_ip:${NODE_EXPORTER_PORT}'"
	write_prometheus_config_node_entry $hostname $targets
done

if [ "$CMD" == "start" ]
then
	start_prometheus
	start_grafana
elif [ "$CMD" == "stop" ]
then
	stop_grafana
	stop_prometheus
fi
#############################
