terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}

provider "kubectl" {
  host  = "https://${var.cluster_ip}:6443"
  cluster_ca_certificate = file(var.cluster_ca_crt_file)
  token = local.cluster_admin_token
}

provider "kubernetes" {
  host  = "https://${var.cluster_ip}:6443"
  cluster_ca_certificate = file(var.cluster_ca_crt_file)
  token = local.cluster_admin_token
}
