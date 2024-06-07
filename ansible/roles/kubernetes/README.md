## k8s

This role initializes a Kubernetes cluster or cluster node.

### Variables

- `k8s_version`: The Kubernetes version to install. (default: `1.30`)
- `crio_version`: The CRI-O version to install. (default: `1.29`)
- `k8s_cluster_endpoint`: The Kubernetes cluster endpoint. (optional for init, required for join)
- `k8s_cluster_token`: The Kubernetes cluster token. (optional for init, required for join)

#### Cluster bootstrap node

- `k8s_kubeadm_init`: Initialize the Kubernetes cluster. (default: `no`)
- `k8s_init_pod_network_cidr`: The pod network CIDR. (default: `10.10.0.0/16`)
- `k8s_init_service_cidr`: The service CIDR. (default: `10.96.0.0/12`)

#### Cluster node

- `k8s_kubeadm_join`: Join the Kubernetes cluster. (default: `no`)
- `k8s_join_as_master`: Join as a control plane node. (default: `no`)
- `k8s_join_discovery_token_ca_cert_hash`: The discovery token CA certificate hash. (required for join)
- `k8_join_certificate_key`: The join certificate key. (required for join)
