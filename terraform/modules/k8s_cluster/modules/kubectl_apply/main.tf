terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

variable "file" {
  description = "A manifest file to apply"
  type        = string
  default     = null
}
// OR
variable "content" {
  description = "Manifest content to apply"
  type        = string
  default     = null
}

// ========================================

locals {
  is_content = var.content != null
  manifest   = local.is_content ? var.content : file(var.file)
  documents = split("---", local.manifest)
}

resource "kubectl_manifest" "documents" {
  count = length(local.documents)
  yaml_body = local.documents[count.index]
}
