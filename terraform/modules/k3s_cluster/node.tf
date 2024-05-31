locals {
  node_network_bits = tonumber(split("/", var.node_network.cidr)[1])

  node_ips = [
    for i in range(var.node_count) : cidrhost(var.node_network.cidr, i + var.node_network.start_host)
  ]

  commands_common = [
    "sudo apt-get update",
    "sudo apt-get install -y curl"
  ]

  head_commands = concat(local.commands_common, [
    "curl -sfL https://get.k3s.io | sudo K3S_TOKEN='${random_password.k3s_cluster_token.result}' sh -s -"
  ])
  agent_commands = concat(local.commands_common, [
    "sleep 60", # wait for the head node to be ready
    "curl -sfL https://get.k3s.io | sudo K3S_TOKEN='${random_password.k3s_cluster_token.result}' K3S_URL='https://${element(local.node_ips, 0)}:6443' sh -s -"
  ])
}

// ====== Head Node ======

resource "proxmox_virtual_environment_vm" "head_node" {
  node_name = var.proxmox_node

  name        = "${var.cluster_name}-node-0"
  description = "${var.cluster_name} cluster head node"
  on_boot     = true

  disk {
    datastore_id = "local-lvm"
    file_id      = var.node_image
    interface    = "scsi0"
  }

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.node_ips[0]}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      username = "ubuntu"
      password = random_password.node_password.result
      keys     = [tls_private_key.node_ssh_key.public_key_openssh]
    }
  }

  network_device {
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  cpu {
    cores = var.node_cpu
  }

  memory {
    dedicated = var.node_memory
  }

  disk {
    interface   = "virtio0"
    file_format = "raw"
    size        = var.node_disk_size
  }

  serial_device {}
}

resource "null_resource" "head_node_provisioner" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = local.node_ips[0]
    private_key = tls_private_key.node_ssh_key.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = local.head_commands
  }

  depends_on = [proxmox_virtual_environment_vm.head_node]
  triggers = { commands = join("\n", local.head_commands) }
}

resource "ssh_resource" "cluster_kubeconfig" {
  user        = "ubuntu"
  host        = element(local.node_ips, 0)
  private_key = tls_private_key.node_ssh_key.private_key_openssh

  commands = [
    "sleep 60", // give the node time to start k3s
    "sudo cat /etc/rancher/k3s/k3s.yaml"
  ]

  depends_on = [null_resource.head_node_provisioner]
}

// ====== Agent Node(s) ======

resource "proxmox_virtual_environment_vm" "agent_node" {
  count     = var.node_count - 1
  node_name = var.proxmox_node

  name        = "${var.cluster_name}-node-${count.index + 1}"
  description = "${var.cluster_name} cluster agent node"
  on_boot     = true

  disk {
    datastore_id = "local-lvm"
    file_id      = var.node_image
    interface    = "scsi0"
  }

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.node_ips[count.index + 1]}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      username = "ubuntu"
      password = random_password.node_password.result
      keys     = [tls_private_key.node_ssh_key.public_key_openssh]
    }
  }

  network_device {
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  cpu {
    cores = var.node_cpu
  }

  memory {
    dedicated = var.node_memory
  }

  disk {
    interface   = "virtio0"
    file_format = "raw"
    size        = var.node_disk_size
  }

  serial_device {}

  depends_on = [proxmox_virtual_environment_vm.head_node]
  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_vm.head_node
    ]
  }
}

resource "null_resource" "agent_node_provisioner" {
  count = var.node_count - 1

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = local.node_ips[count.index+1]
    private_key = tls_private_key.node_ssh_key.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = local.agent_commands
  }

  depends_on = [proxmox_virtual_environment_vm.agent_node]
  triggers = { commands = join("\n", local.agent_commands) }
}

resource "random_password" "k3s_cluster_token" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "random_password" "node_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "node_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

// ====== Local Files ======

resource "local_sensitive_file" "cluster_kubeconfig" {
  count    = var.save_kubeconfig.enabled ? 1 : 0
  content  = ssh_resource.cluster_kubeconfig.result
  filename = var.save_kubeconfig.filename
}

resource "local_sensitive_file" "ssh_private_key" {
  count    = var.save_ssh_key.enabled ? 1 : 0
  content  = tls_private_key.node_ssh_key.private_key_openssh
  filename = var.save_ssh_key.filename
}

resource "local_file" "ssh_public_key" {
  count    = var.save_ssh_key.enabled ? 1 : 0
  content  = tls_private_key.node_ssh_key.public_key_openssh
  filename = "${var.save_ssh_key.filename}.pub"
}

// ====== Outputs ======

output "node_ips" {
  value = local.node_ips
}

output "k3s_cluster_kubeconfig" {
  value     = ssh_resource.cluster_kubeconfig.result
  sensitive = true
}

output "k3s_cluster_token" {
  value     = random_password.k3s_cluster_token.result
  sensitive = true
}

output "node_password" {
  value     = random_password.node_password.result
  sensitive = true
}

output "node_public_key" {
  value = tls_private_key.node_ssh_key.public_key_openssh
}

output "node_private_key" {
  value     = tls_private_key.node_ssh_key.private_key_pem
  sensitive = true
}
