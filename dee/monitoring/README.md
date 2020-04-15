1. Create prometheus config with scrape targets `prometheus.yml`
2. Create a config object using `prometheus.yml`
   ```
   docker config create  prom-config prometheus.yml
   ```

TODO:
- Capture Docker Engine metrics
- 

Reference:
Capturing Engine metrics using swarm global mode - https://medium.com/@basi/docker-swarm-metrics-in-prometheus-e02a6a5745a
https://medium.com/faun/kubernetes-multi-cluster-monitoring-using-prometheus-and-thanos-7549a9b0d0ae
HA Kubernetes Monitoring using Prometheus and Thanos: https://www.metricfire.com/blog/ha-kubernetes-monitoring-using-prometheus-and-thanos

