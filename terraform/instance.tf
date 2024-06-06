resource "proxmox_virtual_environment_container" "instance" {
  node_name = var.proxmox_node

  initialization {
    hostname = "test-instance"

    ip_config {
      ipv4 {
        address = "192.168.3.10/16"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = "12345"
      keys = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
  }

  console {
    type      = "shell"
    enabled   = true
    tty_count = 2
  }
}
