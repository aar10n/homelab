resource "proxmox_virtual_environment_container" "kube_apiserver_lb" {
  node_name = var.proxmox_node

  vm_id         = var.vm_start_id
  description   = "Load balancer for ${var.cluster_name} cluster kube-apiserver"
  start_on_boot = var.start_on_boot
  tags = [var.cluster_name]

  initialization {
    hostname = "${var.cluster_name}-apiserver-lb"

    ip_config {
      ipv4 {
        address = "${var.cluster_ip}/${local.node_network_bits}"
        gateway = var.node_network.gateway
      }
    }

    user_account {
      password = random_password.node_password.result
      keys = [trimspace(tls_private_key.node_ssh_key.public_key_openssh)]
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
    size         = 8
  }

  console {
    type      = "shell"
    enabled   = true
    tty_count = 2
  }
}

resource "time_sleep" "kube_apiserver_lb" {
  depends_on = [proxmox_virtual_environment_container.kube_apiserver_lb]
  create_duration = "80s"
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_container.kube_apiserver_lb]
  }
}

resource "null_resource" "control_plane_ips_changed" {
  triggers = {
    control_plane_ips = join(",", local.control_plane_ips)
  }
}

resource "ansible_playbook" "loadbalancer" {
  playbook   = "../ansible/loadbalancer.yml"
  replayable = false

  name = var.cluster_ip
  extra_vars = {
    ansible_connection           = "ssh"
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local.node_ssh_private_key_file

    loadbalancer_service_name = "kube-apiserver"
    loadbalancer_service_port = 6443
    loadbalancer_backend_servers = jsonencode([
      for ip in local.control_plane_ips : {
        name = "control-plane-${index(local.control_plane_ips, ip)}"
        ip   = ip
        port = 6443
      }
    ])

    local_ca_cert_file = var.cluster_ca_crt_file
  }

  depends_on = [time_sleep.kube_apiserver_lb]
  lifecycle {
    replace_triggered_by = [null_resource.control_plane_ips_changed]
  }
}
