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

// ====== Kubernetes Options ======

variable "enable_cluster_setup" {
  description = "Setup the cluster and install cluster components and after creation"
  type        = bool
  default     = true
}

variable "metallb_address_pool" {
  description = "The IP address pool to use for MetalLB"
  type        = string
  default     = null
}

variable "cert_manager_letsencrypt_issuers" {
  description = "Deploy Let's Encrypt cluster issuers"
  type = object({
    enabled = bool
    email   = string
  })
  default = {
    enabled = false
    email   = ""
  }
}

variable "cert_manager_cloudflare_api_token" {
  description = "The Cloudflare API token for cert-manager's DNS solver"
  type        = string
  sensitive   = true
  default     = null
}

variable "default_gateway" {
  description = "Default cluster gateway configuration"
  type = object({
    enabled = bool
    name = optional(string)
    namespace = optional(string)
    tls = optional(object({
      enabled = bool
      commonName = optional(string)
      dnsNames = optional(list(string))
    }))
  })
  default = {
    enabled   = true
    name      = "gateway"
    namespace = "projectcontour"
    tls = {
      enabled = false
    }
  }
}

variable "gateway_listeners" {
  description = "The listeners to create on the default Gateway"
  type = list(object({
    port     = number
    protocol = string
    name = optional(string)
    hostname = optional(string)
    allowedRoutes = optional(any)
    tls = optional(object({
      mode = optional(string) # "Terminate" or "Passthrough"
      certificateRefs = optional(list(any))
      options = optional(any)
    }))
  }))
  default = [
    {
      port     = 80
      protocol = "HTTP"
    },
    {
      port     = 443
      protocol = "HTTPS"
    }
  ]
}
