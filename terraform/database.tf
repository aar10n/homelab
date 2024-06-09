locals {
  postgres_ip     = "192.168.10.1"
  postgres_domain = "postgres.local"
}

module "postgres_database" {
  source       = "./modules/postgresql"
  proxmox_node = var.proxmox_node

  postgresql_version = "16"
  postgresql_users = [
    { name : "grafana", password : "grafana", db : "grafana" }
  ]
  postgresql_databases = [
    { name : "grafana", owner : "grafana" }
  ]

  instance_network = {
    cidr    = "${local.postgres_ip}/16"
    gateway = "192.168.0.1"
  }

  instance_id          = 400
  instance_cpu         = 1
  instance_memory      = 2048
  instance_disk_size   = 20
  instance_disk_volume = "pool1"
  instance_extra_ssh_keys = [file("~/.ssh/id_ed25519.pub")]

  providers = {
    proxmox = proxmox
  }
}
