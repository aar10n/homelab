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
  host     = var.mikrotik_api_host
  username = var.mikrotik_user
  password = var.mikrotik_password
  tls      = var.mikrotik_tls
  insecure = var.mikrotik_tls
}
