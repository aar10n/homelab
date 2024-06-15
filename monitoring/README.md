# Prometheus Monitoring Stack

This jsonnet directory deploys a complete monitoring stack to Kubernetes. The deployment is based on [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)
and contains the following components:
- prometheus-operator
- prometheus
- prometheus-adapter
- kube-state-metrics
- node-exporter
- alertmanager
- grafana

as well as scraping configurations for the components and the kubernetes control plane.

### Requirements

- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
- [go-jsonnet](https://github.com/google/go-jsonnet)

```
jb install
```

### Deployment

```bash
# install CRDs, namespace and prometheus-operator
make -s render-setup | kubectl apply --server-side -f -
# install the rest of the components
make -s render | kubectl apply --server-side -f -
```
