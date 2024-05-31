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
  }
}
