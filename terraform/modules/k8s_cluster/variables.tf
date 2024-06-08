// ====== Proxmox Options ======

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
}

// ====== Cluster Options ======

variable "cluster_name" {
  description = "The name of the kubernetes cluster"
  type        = string
}

variable "cluster_ip" {
  description = "The IP address of the cluster API server"
  type        = string
}

variable "cluster_dns_server" {
  description = "The IP address of an upstream DNS server to use"
  type        = string
  default     = null
}

variable "pod_network_cidr" {
  description = "The CIDR range for the pod network"
  type        = string
  default     = "10.10.0.0/16"
}

variable "service_network_cidr" {
  description = "The CIDR range for the service network"
  type        = string
  default     = "10.96.0.0/12"
}

variable "cluster_ca_crt_file" {
  description = "The path to a CA certificate file to use for this cluster"
  default     = null
}

variable "cluster_ca_key_file" {
  description = "The path to a CA key file to use for this cluster"
  default     = null
}

// ====== Node Options ======

variable "node_network" {
  description = "Node network configuration"
  type = object({
    cidr       = string
    gateway    = string
    start_host = number
  })
}

variable "loadbalancer_instance" {
  description = "API server loadbalancer instance configuration"
  type = object({
    cpu         = number
    memory      = number
    disk_volume = string
    disk_size   = number
    template    = string
  })
  default = {
    cpu         = 1,
    memory      = 512,
    disk_volume = "local-lvm",
    disk_size   = 4,
    template    = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  }
}

variable "control_plane_nodes" {
  description = "Control plane node configuration"
  type = object({
    count       = number
    cpu         = number
    memory      = number
    disk_volume = string
    disk_size   = number
    image       = string
  })
  default = {
    count       = 3,
    cpu         = 2,
    memory      = 2048,
    disk_volume = "local-lvm",
    disk_size   = 10,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }
}

variable "worker_nodes" {
  description = "Worker node configuration"
  type = object({
    count       = number
    cpu         = number
    memory      = number
    disk_volume = string
    disk_size   = number
    image       = string
  })
  default = {
    count       = 2,
    cpu         = 2,
    memory      = 2048,
    disk_volume = "local-lvm",
    disk_size   = 10,
    image       = "local:iso/jammy-server-cloudimg-amd64.img",
  }
}

variable "start_on_boot" {
  description = "Start the nodes on boot"
  type        = bool
  default     = true
}

variable "vm_start_id" {
  description = "The starting ID for the VMs"
  default     = null
}

variable "worker_id_offset" {
  description = "The offset of the worker node IDs from vm_start_id"
  default     = 50
}

// ====== Kubernetes Options ======

variable "metallb_address_pool" {
  description = "The IP address pool to use for MetalLB"
  type        = string
  default     = null
}

variable "emissary_port_listeners" {
  description = "The ports to create Emissary listeners for"
  type = list(object({
    port     = number
    protocol = string
  }))
  default = [
    {
      port     = 8080
      protocol = "HTTPS"
    }
  ]
}

// ====== Local Files ======

variable "kubeconfig_save_file" {
  description = "The path to save the kubeconfig file"
  type        = string
  default     = null
}

variable "ssh_key_save_file" {
  description = "The path to save the node SSH key file"
  type        = string
  default     = null
}
