module "k8s_cluster" {
  source       = "./modules/k8s_cluster"
  proxmox_node = var.proxmox_node

  cluster_name         = "k8s"
  cluster_ip           = "192.168.10.0"
  pod_network_cidr     = "10.244.0.0/16"
  service_network_cidr = "10.96.0.0/12"
  metallb_address_pool = "192.168.100.0/24"
  vm_start_id          = 500

  node_network = {
    cidr       = "192.168.0.0/16"
    gateway    = "192.168.0.1"
    start_host = (8 * 256) # 192.168.8.0
  }

  control_plane_nodes = {
    count       = 3,
    cpu         = 2,
    memory      = 2048,
    disk_volume = "pool1",
    disk_size   = 10,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }

  worker_nodes = {
    count       = 3,
    cpu         = 2,
    memory      = 4096,
    disk_volume = "pool2",
    disk_size   = 40,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }

  cluster_ca_crt_file = pathexpand("~/.certs/rootCA.pem")
  cluster_ca_key_file = pathexpand("~/.certs/rootCA-key.pem")

  kubeconfig_save_file = pathexpand("~/.kube/k8s_cluster_config")
  ssh_key_save_file = pathexpand("~/.ssh/k8s_cluster_key")

  providers = {
    proxmox  = proxmox
    mikrotik = mikrotik
  }
}
