// ====== Proxmox ======

variable "proxmox_host" {
  description = "The hostname of the Proxmox server"
  type        = string
}

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
}

variable "proxmox_user" {
  description = "The API user for connecting to Proxmox"
  type        = string
}

variable "proxmox_password" {
  description = "The password for connecting to Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure connections to Proxmox"
  type        = bool
  default     = false
}

variable "proxmox_ssh_user" {
  description = "The ssh user for connecting to Proxmox"
  type        = string
}

variable "proxmox_ssh_password" {
  description = "The ssh password for connecting to Proxmox"
  type        = string
  sensitive   = true
  default     = null
}

variable "proxmox_ssh_agent" {
  description = "Use the ssh agent for connecting to Proxmox"
  type        = bool
  default     = false
}

// ====== MikroTik ======

variable "mikrotik_host" {
  description = "The hostname of the MikroTik router"
  type        = string
}

variable "mikrotik_user" {
  description = "The username for connecting to the MikroTik router"
  type        = string
}

variable "mikrotik_password" {
  description = "The password for connecting to the MikroTik router"
  type        = string
  sensitive   = true
}

variable "mikrotik_tls" {
  description = "Use TLS to connect to the MikroTik router"
  type        = bool
  default     = true
}

variable "mikrotik_insecure" {
  description = "Allow insecure connections to the MikroTik router"
  type        = bool
  default     = false
}
