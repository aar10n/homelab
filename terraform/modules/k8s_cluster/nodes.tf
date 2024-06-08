locals {
  cluster_endpoint = "${var.cluster_ip}:6443"
  cluster_join_token = sensitive("${random_password.cluster_token_part_a.result}.${random_password.cluster_token_part_b.result}")
  cluster_discovery_token_ca_cert_hash = sensitive("sha256:${trimspace(ssh_sensitive_resource.cluster_discovery_token_ca_cert_hash.result)}")
  cluster_certificate_key = sensitive(trimspace(ssh_sensitive_resource.cluster_certificate_key.result))
  node_network_bits = tonumber(split("/", var.node_network.cidr)[1])

  control_plane_ips = [
    for i in range(var.control_plane_nodes.count) :
    cidrhost(var.node_network.cidr, i + var.node_network.start_host)
  ]
  worker_node_ips = [
    for i in range(var.worker_nodes.count) :
    cidrhost(var.node_network.cidr, i + var.node_network.start_host + var.control_plane_nodes.count)
  ]

  tmp_cluster_config_file       = "/tmp/${var.cluster_name}_kubeconfig"
  tmp_node_ssh_private_key_file = "/tmp/${var.cluster_name}_node_ssh_private_key"

  cluster_kubeconfig_file = (var.kubeconfig_save_file != null ? var.kubeconfig_save_file :
    local.tmp_cluster_config_file)
  node_ssh_private_key_file = (var.ssh_key_save_file != null ? var.ssh_key_save_file :
    local.tmp_node_ssh_private_key_file)
  cluster_admin_token = trimspace(ssh_sensitive_resource.cluster_admin_token.result)
}

//
// ====== Control Plane Init Node ======
//

resource "proxmox_virtual_environment_vm" "control_plane_init_node" {
  node_name = var.proxmox_node

  vm_id       = var.vm_start_id == null ? null : var.vm_start_id + 1
  name        = "${var.cluster_name}-control-plane-0"
  description = "Control plane node for ${var.cluster_name} cluster (bootstrap node)"
  on_boot     = var.start_on_boot
  tags = [var.cluster_name, "control-plane"]

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.control_plane_ips[0]}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      username = "ubuntu"
      password = random_password.node_password.result
      keys = [trimspace(tls_private_key.node_ssh_key.public_key_openssh)]
    }
  }

  network_device {
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  cpu {
    cores = var.control_plane_nodes.cpu
  }

  memory {
    dedicated = var.control_plane_nodes.memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    file_id      = var.control_plane_nodes.image
  }

  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = var.control_plane_nodes.disk_volume
    size         = var.control_plane_nodes.disk_size
  }

  serial_device {}

  depends_on = [ansible_playbook.loadbalancer]

  provisioner "local-exec" {
    when    = create
    command = "until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.node_ssh_private_key_file} ubuntu@${local.control_plane_ips[0]} echo 'SSH is ready'; do sleep 5; done"
  }
}

resource "ansible_playbook" "control_plane_init" {
  playbook   = "../ansible/kubernetes.yml"
  replayable = false

  name = local.control_plane_ips[0]
  groups = ["k8s_master"]
  extra_vars = {
    ansible_connection           = "ssh"
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = local.node_ssh_private_key_file

    k8s_kubeadm_init          = true
    k8s_kubeadm_join          = true
    k8s_cluster_token         = local.cluster_join_token
    k8s_cluster_endpoint      = local.cluster_endpoint
    k8s_init_pod_network_cidr = var.pod_network_cidr
    k8s_init_service_cidr     = var.service_network_cidr

    local_ca_cert_file       = var.cluster_ca_crt_file
    local_ca_key_file        = var.cluster_ca_key_file
    local_ca_install_for_k8s = var.cluster_ca_key_file != null
  }

  depends_on = [proxmox_virtual_environment_vm.control_plane_init_node]
}

// cluster secrets

resource "ssh_sensitive_resource" "cluster_kubeconfig" {
  user        = "ubuntu"
  host = element(local.control_plane_ips, 0)
  private_key = tls_private_key.node_ssh_key.private_key_openssh
  commands = ["sudo cat /etc/kubernetes/admin.conf"]
  depends_on = [ansible_playbook.control_plane_init]
}

resource "ssh_sensitive_resource" "cluster_admin_token" {
  user        = "ubuntu"
  host = element(local.control_plane_ips, 0)
  private_key = tls_private_key.node_ssh_key.private_key_openssh
  commands = ["cat /tmp/cluster_admin_token"]
  depends_on = [ansible_playbook.control_plane_init]
}

resource "ssh_sensitive_resource" "cluster_discovery_token_ca_cert_hash" {
  user        = "ubuntu"
  host = element(local.control_plane_ips, 0)
  private_key = tls_private_key.node_ssh_key.private_key_openssh
  commands = ["cat /tmp/discovery_token_ca_cert_hash"]
  depends_on = [ansible_playbook.control_plane_init]
}

resource "ssh_sensitive_resource" "cluster_certificate_key" {
  user        = "ubuntu"
  host = element(local.control_plane_ips, 0)
  private_key = tls_private_key.node_ssh_key.private_key_openssh
  commands = ["cat /tmp/certificate_key"]
  depends_on = [ansible_playbook.control_plane_init]
}

//
// ====== Control Plane Nodes ======
//

resource "proxmox_virtual_environment_vm" "control_plane_node" {
  count = max(0, var.control_plane_nodes.count - 1)
  node_name = var.proxmox_node

  vm_id       = var.vm_start_id == null ? null : var.vm_start_id + count.index + 2
  name        = "${var.cluster_name}-control-plane-${count.index+1}"
  description = "Control plane node for ${var.cluster_name} cluster"
  on_boot     = var.start_on_boot
  tags = [var.cluster_name, "control-plane"]

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.control_plane_ips[count.index+1]}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      username = "ubuntu"
      password = random_password.node_password.result
      keys = [trimspace(tls_private_key.node_ssh_key.public_key_openssh)]
    }
  }

  network_device {
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  cpu {
    cores = var.control_plane_nodes.cpu
  }

  memory {
    dedicated = var.control_plane_nodes.memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    file_id      = var.control_plane_nodes.image
  }

  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = var.control_plane_nodes.disk_volume
    size         = var.control_plane_nodes.disk_size
  }

  serial_device {}

  depends_on = [proxmox_virtual_environment_vm.control_plane_init_node]
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.control_plane_init_node]
  }

  provisioner "local-exec" {
    when    = create
    command = "until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.node_ssh_private_key_file} ubuntu@${local.control_plane_ips[count.index+1]} echo 'SSH is ready'; do sleep 5; done"
  }
}

resource "ansible_playbook" "control_plane_join" {
  count = max(0, var.control_plane_nodes.count - 1)
  playbook   = "../ansible/kubernetes.yml"
  replayable = false

  name = local.control_plane_ips[count.index+1]
  groups = ["k8s_master"]
  extra_vars = {
    ansible_connection           = "ssh"
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = local.node_ssh_private_key_file

    k8s_kubeadm_join                      = true
    k8s_cluster_token                     = local.cluster_join_token
    k8s_cluster_endpoint                  = local.cluster_endpoint
    k8s_join_discovery_token_ca_cert_hash = local.cluster_discovery_token_ca_cert_hash
    k8s_join_certificate_key              = local.cluster_certificate_key

    local_ca_cert_file = var.cluster_ca_crt_file
  }

  depends_on = [proxmox_virtual_environment_vm.control_plane_node]
}

//
// ====== Worker Nodes ======
//

resource "proxmox_virtual_environment_vm" "worker_node" {
  count     = var.worker_nodes.count
  node_name = var.proxmox_node

  vm_id       = var.vm_start_id == null ? null : var.vm_start_id + var.worker_id_offset + count.index
  name        = "${var.cluster_name}-worker-${count.index}"
  description = "Worker node for ${var.cluster_name} cluster"
  on_boot     = var.start_on_boot
  tags = [var.cluster_name, "worker"]

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.worker_node_ips[count.index]}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      username = "ubuntu"
      password = random_password.node_password.result
      keys = [trimspace(tls_private_key.node_ssh_key.public_key_openssh)]
    }
  }

  network_device {
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  cpu {
    cores = var.worker_nodes.cpu
  }

  memory {
    dedicated = var.worker_nodes.memory
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    file_id      = var.worker_nodes.image
  }

  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = var.worker_nodes.disk_volume
    size         = var.worker_nodes.disk_size
  }

  serial_device {}

  depends_on = [proxmox_virtual_environment_vm.control_plane_node]
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.control_plane_node]
  }

  provisioner "local-exec" {
    when    = create
    command = "until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.node_ssh_private_key_file} ubuntu@${local.worker_node_ips[count.index]} echo 'SSH is ready'; do sleep 5; done"
  }
}

resource "ansible_playbook" "cluster_worker_join" {
  count      = var.worker_nodes.count
  playbook   = "../ansible/kubernetes.yml"
  replayable = false

  name = local.worker_node_ips[count.index]
  groups = ["k8s_worker"]
  extra_vars = {
    ansible_connection           = "ssh"
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = local.node_ssh_private_key_file

    k8s_kubeadm_join                      = true
    k8s_cluster_token                     = local.cluster_join_token
    k8s_cluster_endpoint                  = local.cluster_endpoint
    k8s_join_discovery_token_ca_cert_hash = local.cluster_discovery_token_ca_cert_hash
    k8s_join_certificate_key              = local.cluster_certificate_key

    local_ca_cert_file = var.cluster_ca_crt_file
  }

  depends_on = [proxmox_virtual_environment_vm.worker_node]
}

// ====== Secrets ======

resource "random_password" "cluster_token_part_a" {
  length  = 6
  numeric = true
  lower   = true
  upper   = false
  special = false
}

resource "random_password" "cluster_token_part_b" {
  length  = 16
  numeric = true
  lower   = true
  upper   = false
  special = false
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

// ====== Files ======

resource "local_sensitive_file" "cluster_kubeconfig" {
  count    = var.kubeconfig_save_file != null ? 1 : 0
  content  = ssh_sensitive_resource.cluster_kubeconfig.result
  filename = local.cluster_kubeconfig_file
}

resource "local_file" "node_ssh_public_key" {
  content  = tls_private_key.node_ssh_key.public_key_openssh
  filename = "${local.node_ssh_private_key_file}.pub"
}

resource "local_sensitive_file" "node_ssh_private_key" {
  content  = tls_private_key.node_ssh_key.private_key_openssh
  filename = local.node_ssh_private_key_file
}
