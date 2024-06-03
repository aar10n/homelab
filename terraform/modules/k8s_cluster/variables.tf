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

variable "control_plane_node_count" {
  description = "The number of control plane nodes to create"
  default     = 3
  validation {
    condition     = var.control_plane_node_count > 0
    error_message = "The control plane node count must be greater than 0"
  }
}

variable "worker_node_count" {
  description = "The number of worker nodes to create"
  default     = 2
}

variable "node_network" {
  description = "Node network configuration"
  type = object({
    cidr       = string
    gateway    = string
    start_host = number
  })
}

variable "node_image" {
  description = "The unique ID of the Proxmox image to use for the nodes"
  default     = "local:iso/jammy-server-cloudimg-amd64.img"
}

variable "node_cpu" {
  description = "The number of CPU cores to allocate to each node"
  default     = 2
}

variable "node_memory" {
  description = "The amount of memory to allocate to each node"
  default     = 2048
}

variable "node_disk_size" {
  description = "The size of the disk to allocate to each node"
  default     = 10
}

variable "node_disk_volume" {
  description = "The name of the storage volume to use for the node disks"
  default     = "local-lvm"
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

// ====== Local Files ======

variable "save_kubeconfig" {
  description = "Save the kubeconfig to a file"
  type = object({
    enabled  = bool
    filename = string
  })
  default = {
    enabled  = true
    filename = "kubeconfig.yaml"
  }
  validation {
    condition     = var.save_kubeconfig.enabled && var.save_kubeconfig.filename != ""
    error_message = "If save_kubeconfig is enabled, a filename must be provided"
  }
}

variable "save_node_ssh_key" {
  description = "Save the node SSH key to a file"
  type = object({
    enabled  = bool
    filename = string
  })
  default = {
    enabled  = false
    filename = ""
  }
  validation {
    condition     = var.save_node_ssh_key.enabled && var.save_node_ssh_key.filename != ""
    error_message = "If save_node_ssh_key is enabled, a filename must be provided"
  }
}

