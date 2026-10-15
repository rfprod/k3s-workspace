variable "namespace_name" {
  description = "Kubernetes namespace where storage resources will be created"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to all storage resources"
  type        = map(string)
  default = {
    environment = "local"
    managed_by  = "terraform"
  }
}

variable "storage_classes" {
  description = "StorageClass definitions for the cluster"
  type = map(object({
    provisioner            = string
    reclaim_policy         = optional(string, "Delete")
    allow_volume_expansion = optional(bool, true)
    volume_binding_mode    = optional(string, "Immediate")
    parameters             = optional(map(string), null)
  }))
  default = {
    "local-path" = {
      provisioner         = "rancher.io/local-path"
      reclaim_policy      = "Delete"
      volume_binding_mode = "WaitForFirstConsumer"
    }
  }
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "persistent_volume_claims" {
  description = "PersistentVolumeClaims to create"
  type = map(object({
    access_modes  = list(string)
    storage_class = string
    size          = string
  }))
  default = {}
}
