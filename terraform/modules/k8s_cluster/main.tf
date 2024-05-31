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
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    mikrotik = {
      source  = "ddelnano/mikrotik"
      version = "0.15.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.1"
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
  config_path = local.cluster_kubeconfig_file
}

provider "kubernetes" {
  config_path = local.cluster_kubeconfig_file
}
