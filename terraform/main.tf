terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.1"
    }
    mikrotik = {
      source  = "ddelnano/mikrotik"
      version = "0.15.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}

// ============ Providers ============

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/"
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = var.proxmox_insecure
  tmp_dir  = "/var/tmp"
  ssh {
    username = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    agent    = var.proxmox_ssh_agent
  }
}

provider "mikrotik" {
  host     = var.mikrotik_host
  username = var.mikrotik_user
  password = var.mikrotik_password
  tls      = var.mikrotik_tls
  insecure = var.mikrotik_tls
}

// ============ Modules ============

# module "k3s_cluster" {
#   source               = "./modules/k3s_cluster"
#   proxmox_node         = var.proxmox_node
#   proxmox_host         = var.proxmox_host
#   proxmox_ssh_user     = var.proxmox_ssh_user
#   proxmox_ssh_password = var.proxmox_ssh_password
#   proxmox_ssh_agent    = var.proxmox_ssh_agent
#
#   cluster_name = "k3s"
#   node_count   = 3
#
#   node_network = {
#     cidr       = "192.168.0.0/16"
#     gateway    = "192.168.0.1"
#     start_host = (256 * 3) # 192.168.3.0
#   }
#
#   #   pod_network     = "10.1.0.0/16"
#   #   service_network = "10.2.0.0/16"
#
#   save_kubeconfig = {
#     enabled  = true
#     filename = pathexpand("~/.kube/k3s_cluster_kubeconfig.yaml")
#   }
#
#   save_ssh_key = {
#     enabled  = true,
#     filename = pathexpand("~/.ssh/k3s_cluster_key")
#   }
#
#   providers = {
#     proxmox  = proxmox
#     mikrotik = mikrotik
#   }
# }

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
