module "k8s_cluster" {
  source       = "./modules/k8s_cluster"
  proxmox_node = var.proxmox_node

  cluster_name         = "k8s"
  cluster_ip           = "192.168.10.0"
  cluster_dns_server   = "192.168.0.1"
  pod_network_cidr     = "10.244.0.0/16"
  service_network_cidr = "10.96.0.0/12"
  vm_start_id          = 500

  cluster_ca_crt_file = pathexpand("~/.certs/rootCA.pem")
  cluster_ca_key_file = pathexpand("~/.certs/rootCA-key.pem")

  node_network = {
    cidr       = "192.168.0.0/16"
    gateway    = "192.168.0.1"
    start_host = (8 * 256) # 192.168.8.0
  }

  control_plane_nodes = {
    count       = 3,
    cpu         = 2,
    memory      = 2048,
    disk_volume = "pool1",
    disk_size   = 10,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }

  worker_nodes = {
    count       = 3,
    cpu         = 2,
    memory      = 4096,
    disk_volume = "pool2",
    disk_size   = 40,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }

  // ====== Cluster Setup ======

  enable_cluster_setup              = true
  metallb_address_pool              = "192.168.100.10-192.168.100.250"
  cert_manager_cloudflare_api_token = var.cloudflare_api_token
  cert_manager_letsencrypt_issuers = {
    enabled = true
    email   = "aarongillbraun@gmail.com"
  }
  default_gateway = {
    enabled = true
    tls = {
      enabled = true
      dnsNames = [
        "home.agb.dev",
        "*.home.agb.dev"
      ]
    }
  }

  providers = {
    proxmox = proxmox
  }
}

resource "local_sensitive_file" "cluster_kubeconfig" {
  content = module.k8s_cluster.cluster_kubeconfig
  filename = pathexpand("~/.kube/k8s_cluster_config")
}

resource "local_sensitive_file" "node_ssh_private_key" {
  content = module.k8s_cluster.node_private_key
  filename = pathexpand("~/.ssh/k8s_cluster_key")
}

resource "local_file" "node_ssh_public_key" {
  content = module.k8s_cluster.node_public_key
  filename = pathexpand("~/.ssh/k8s_cluster_key.pub")
}

// ====== Outputs ======

output "cluster_gateway_ip" {
  value = module.k8s_cluster.gateway_external_ip
}
