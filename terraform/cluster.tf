locals {
  k8s_cluster_ip = "192.168.10.0"
}

module "k8s_cluster" {
  source       = "./modules/k8s_cluster"
  proxmox_node = var.proxmox_node

  cluster_name             = "k8s"
  cluster_ip               = local.k8s_cluster_ip
  control_plane_node_count = 3
  worker_node_count        = 3
  vm_start_id              = 500

  node_network = {
    cidr       = "192.168.0.0/16"
    gateway    = "192.168.0.1"
    start_host = (5 * 256) # 192.168.5.0
  }

  cluster_ca_crt_file = pathexpand("~/.certs/rootCA.pem")
  cluster_ca_key_file = pathexpand("~/.certs/rootCA-key.pem")

  save_kubeconfig = {
    enabled = true
    filename = pathexpand("~/.kube/k8s_cluster_config")
  }
  save_node_ssh_key = {
    enabled = true,
    filename = pathexpand("~/.ssh/k8s_cluster_key")
  }

  providers = {
    proxmox  = proxmox
    mikrotik = mikrotik
  }
}
