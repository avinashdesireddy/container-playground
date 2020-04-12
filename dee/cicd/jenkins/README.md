
Interlock config doesnot include "proxy_set_header        X-Forwarded-Proto $scheme"

It is required for Jenkins.

To update interlock config - Capture the config.toml file and modify the HTTPOptions and reload the config.toml file

https://docs.docker.com/ee/ucp/interlock/config/
docker stack deploy -c docker-compose.yml ci


docker config inspect --format '{{ printf "%s" .Spec.Data }}' $(docker service inspect --format '{{(index .Spec.TaskTemplate.ContainerSpec.Configs 0).ConfigName}}' ucp-interlock-proxy) > interlock-nginx.conf
