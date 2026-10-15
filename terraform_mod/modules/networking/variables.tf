variable "namespace_name" {
  description = "Kubernetes namespace where networking resources will be created"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to all networking resources"
  type        = map(string)
  default = {
    environment = "local"
    managed_by  = "terraform"
  }
}

variable "ingress_class_name" {
  description = "Ingress class name (traefik for local k3s, nginx for others)"
  type        = string
  default     = "traefik"
}

variable "ingress_annotations" {
  description = "Default annotations for all Ingress resources"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-staging"
  }
}

variable "ingress_resources" {
  description = "Ingress resources to create"
  type = map(object({
    annotations = optional(map(string), {})
    rules = list(object({
      host = string
      paths = list(object({
        path         = string
        path_type    = optional(string, "Prefix")
        service_name = string
        service_port = number
      }))
    }))
    tls = optional(object({
      hosts       = list(string)
      secret_name = string
    }), null)
  }))
  default = {}
}

variable "network_policies" {
  description = "NetworkPolicy resources to create"
  type = map(object({
    pod_selector_labels = map(string)
    policy_types        = list(string)
    ingress_rules = optional(list(object({
      from = optional(list(object({
        pod_selector = optional(object({
          match_labels = map(string)
        }), null)
        namespace_selector = optional(object({
          match_labels = map(string)
        }), null)
      })), [])
      ports = optional(list(object({
        protocol = optional(string, "TCP")
        port     = number
      })), [])
    })), [])
    egress_rules = optional(list(object({
      to = optional(list(object({
        pod_selector = optional(object({
          match_labels = map(string)
        }), null)
        namespace_selector = optional(object({
          match_labels = map(string)
        }), null)
      })), [])
      ports = optional(list(object({
        protocol = optional(string, "TCP")
        port     = number
      })), [])
    })), [])
  }))
  default = {}
}
