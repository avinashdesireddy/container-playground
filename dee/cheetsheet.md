
## Obtain Docker components version
```bash
docker version --format '{{println .Server.Platform.Name}}Client: {{.Client.Version}}{{range .Server.Components}}{{println}}{{.Name}}: {{.Version}}{{end}}'
```

## UCP Health Check
## API Call
```bash
$ curl -k https://<ucp-node-hostname>:443/_ping
```

### Command-line on UCP Manager node
```bash
$ docker exec -it ucp-kv etcdctl \
--endpoint https://127.0.0.1:2379 \
--ca-file /etc/docker/ssl/ca.pem \
--cert-file /etc/docker/ssl/cert.pem \
--key-file /etc/docker/ssl/key.pem \
cluster-health
```

## DTR Health Check
### API Call
```bash
# For each DTR host
$ curl -k https://<dtr-node-hostname>:443/_ping

## Returns extensive information about all DTR replicas.
$ curl -k https://dtr.dockeree.com/api/v0/meta/cluster_status
```


