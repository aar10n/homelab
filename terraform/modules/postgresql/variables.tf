variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
}

// ====== PostgreSQL Options ======

variable "postgresql_version" {
  description = "The version of PostgreSQL to install"
  type        = string
  default     = "15"
}

variable "postgresql_users" {
  description = "A list of users to create in the PostgreSQL database"
  sensitive   = true
  default     = null
  type = list(object({
    name     = string
    password = string
    db       = string // optional
  }))
}

variable "postgresql_databases" {
  description = "A list of databases to create in the PostgreSQL database"
  sensitive   = true
  default     = null
  type = list(object({
    name  = string
    owner = string
  }))
}

// ====== Instance Options ======

variable "instance_network" {
  description = "Network configuration for the database instance"
  type = object({
    cidr    = string
    gateway = string
  })
}

variable "instance_hostname" {
  description = "The hostname to assign to the database instance"
  type        = string
  default     = "postgresql"
}

variable "instance_id" {
  description = "The ID of the database instance"
  type        = number
  default     = null
}

variable "instance_template_id" {
  description = "The template to use for the database instance"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "instance_cpu" {
  description = "The number of CPU cores to allocate to the database instance"
  type        = number
  default     = 2
}

variable "instance_memory" {
  description = "The amount of memory to allocate to the database instance"
  type        = number
  default     = 2048
}

variable "instance_disk_size" {
  description = "The size of the disk to allocate to the database instance"
  type        = number
  default     = 10
}

variable "instance_disk_volume" {
  description = "The volume to use for the database instance"
  type        = string
  default     = "local-lvm"
}

variable "instance_extra_ssh_keys" {
  description = "Extra SSH public keys to add to the database instance"
  type = list(string)
  default = []
}

variable "start_on_boot" {
  description = "Start the database instance on boot"
  type        = bool
  default     = true
}

// ====== Other ======

variable "tmp_dir" {
  description = "The temporary directory to use for temporary files"
  type        = string
  default     = "/tmp"
}
