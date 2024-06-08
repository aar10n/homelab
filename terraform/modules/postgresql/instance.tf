locals {
  instance_ip               = split("/", var.instance_network.cidr)[0]
  instance_ssh_key_tmp_file = "${var.tmp_dir}/${sha1(tls_private_key.instance_ssh_key.public_key_openssh)}"
}

resource "proxmox_virtual_environment_container" "posgresql" {
  node_name = var.proxmox_node

  vm_id         = var.instance_id
  description   = "PostgreSQL ${var.postgresql_version} Database"
  start_on_boot = var.start_on_boot

  initialization {
    hostname = var.instance_hostname

    ip_config {
      ipv4 {
        address = var.instance_network.cidr
        gateway = var.instance_network.gateway
      }
    }

    user_account {
      password = random_password.instance_password.result
      keys = concat(
        [trimspace(tls_private_key.instance_ssh_key.public_key_openssh)],
        [for key in var.instance_extra_ssh_keys : trimspace(key)]
      )
    }
  }

  cpu {
    cores = var.instance_cpu
  }

  memory {
    dedicated = var.instance_memory
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }

  operating_system {
    template_file_id = var.instance_template_id
    type             = "ubuntu"
  }

  disk {
    datastore_id = var.instance_disk_volume
    size         = var.instance_disk_size
  }

  console {
    type      = "shell"
    enabled   = true
    tty_count = 2
  }
}

resource "time_sleep" "postgresql_instance" {
  depends_on = [proxmox_virtual_environment_container.posgresql]
  create_duration = "90s"
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_container.posgresql]
  }
}

resource "null_resource" "postgresql_trigger" {
  depends_on = [time_sleep.postgresql_instance]
  triggers = {
    postgres_version = var.postgresql_version
    postgres_users = jsonencode(var.postgresql_users)
    postgres_databases = jsonencode(var.postgresql_databases)
  }
}

resource "ansible_playbook" "postgresql" {
  playbook   = "../ansible/postgresql.yml"
  replayable = false

  name = local.instance_ip
  extra_vars = {
    ansible_connection           = "ssh"
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local.instance_ssh_key_tmp_file

    postgresql_version = var.postgresql_version
    postgresql_users = jsonencode(var.postgresql_users)
    postgresql_databases = jsonencode(var.postgresql_databases)
  }

  depends_on = [null_resource.postgresql_trigger]
  lifecycle {
    replace_triggered_by = [null_resource.postgresql_trigger]
  }
}

// ====== Secrets ======

resource "random_password" "instance_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "instance_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

// ====== Files ======

resource "local_file" "tmp_instance_ssh_private_key" {
  content         = tls_private_key.instance_ssh_key.private_key_openssh
  filename        = local.instance_ssh_key_tmp_file
  file_permission = "0600"
}
