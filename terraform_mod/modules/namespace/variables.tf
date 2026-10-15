variable "namespace_name" {
  description = "Name of the Kubernetes namespace to create"
  type        = string
}

# The `default` service account is cluster-manged.
# variable "service_account_name" {
#   description = "Name of the ServiceAccount to create in the namespace"
#   type        = string
#   default     = "default"
# }

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "local"
    managed_by  = "terraform"
  }
}

variable "create_read_only_role" {
  description = "Whether to create a read-only ClusterRole for the namespace"
  type        = bool
  default     = false
}

variable "create_admin_role" {
  description = "Whether to create an admin Role for the namespace"
  type        = bool
  default     = false
}

variable "create_network_policy" {
  description = "Whether to create a default-deny network policy"
  type        = bool
  default     = false
}

variable "resource_quota_enabled" {
  description = "Whether to enable ResourceQuota for the namespace"
  type        = bool
  default     = false
}

variable "resource_quota_limits" {
  description = "Resource quota limits for the namespace"
  type        = map(string)
  default = {
    "requests.cpu"    = "500m"
    "requests.memory" = "1Gi"
    "limits.cpu"      = "1"
    "limits.memory"   = "2Gi"
    "pods"            = "50"
  }
}
