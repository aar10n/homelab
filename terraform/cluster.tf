locals {
  cluster_config_file = pathexpand("~/.kube/k8s_cluster_config")
  node_ssh_key_file = pathexpand("~/.ssh/k8s_cluster_key")
  ca_crt_file = pathexpand("~/.certs/rootCA.pem")
  ca_key_file = pathexpand("~/.certs/rootCA-key.pem")
}

module "k8s_cluster" {
  source               = "./modules/k8s_cluster"
  proxmox_node         = var.proxmox_node
  proxmox_host         = var.proxmox_host
  proxmox_ssh_user     = var.proxmox_ssh_user
  proxmox_ssh_password = var.proxmox_ssh_password
  proxmox_ssh_agent    = var.proxmox_ssh_agent

  cluster_name             = "k8s"
  cluster_ip               = "192.168.10.0"
  control_plane_node_count = 3
  worker_node_count        = 3
  vm_start_id              = 500

  node_network = {
    cidr       = "192.168.0.0/16"
    gateway    = "192.168.0.1"
    start_host = (5 * 256) # 192.168.5.0
  }

  cluster_ca_crt_file = local.ca_crt_file
  cluster_ca_key_file = local.ca_key_file

  save_kubeconfig = {
    enabled  = true
    filename = local.cluster_config_file
  }
  save_node_ssh_key = {
    enabled  = true,
    filename = local.node_ssh_key_file
  }

  providers = {
    proxmox  = proxmox
    mikrotik = mikrotik
  }
}
