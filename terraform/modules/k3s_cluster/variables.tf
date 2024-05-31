// ====== Proxmox Options ======

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
}

variable "proxmox_host" {
  description = "The hostname of the Proxmox server"
  type        = string
}

variable "proxmox_ssh_user" {
  description = "The ssh user for connecting to Proxmox"
  type        = string
}

variable "proxmox_ssh_password" {
  description = "The ssh password for connecting to Proxmox"
  sensitive   = true
  type        = string
}

variable "proxmox_ssh_agent" {
  description = "Use the ssh agent for connecting to Proxmox"
  type        = bool
  default     = false
}

variable "start_on_boot" {
  description = "Start the container on boot"
  default     = true
}

variable "save_kubeconfig" {
  description = "Save the kubeconfig to a file"
  type        = object({
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

variable "save_ssh_key" {
  description = "Save the SSH key to a file"
  type        = object({
    enabled  = bool
    filename = string
  })
  default = {
    enabled  = false
    filename = ""
  }
  validation {
    condition     = var.save_ssh_key.enabled && var.save_ssh_key.filename != ""
    error_message = "If save_ssh_key is enabled, a filename must be provided"
  }
}

// ====== Cluster Options ======

variable "cluster_name" {
  description = "The name of the k3s cluster"
  type        = string
}

variable "node_network" {
  description = "Node network configuration"
  type        = object({
    cidr       = string
    gateway    = string
    start_host = number
  })
}

variable "node_count" {
  description = "The number of nodes to create"
  default     = 3
  validation {
    condition     = var.node_count > 0
    error_message = "The node count must be greater than 0"
  }
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
