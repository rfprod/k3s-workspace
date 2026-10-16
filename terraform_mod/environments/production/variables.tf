variable "kubeconfig_path" {
  description = "Path to kubeconfig for local k3s cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context name"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "managed_by" {
  description = "Managed by"
  type        = string
  default     = "terraform"
}

variable "pvc_configs_production" {
  description = "PVC configurations for production environment"
  type = map(object({
    access_modes  = list(string)
    storage_class = optional(string, "local-path")
    size          = string
  }))
  default = {
    redis = {
      access_modes  = ["ReadWriteOnce"]
      storage_class = "local-path"
      size          = "3Gi"
    }
  }
}

variable "deployments_production" {
  description = "Kubernetes Deployments to create"
  type = map(object({
    replicas                         = optional(number, 1)
    labels                           = optional(map(string), {})
    annotations                      = optional(map(string), {})
    pod_selector_labels              = map(string)
    pod_annotations                  = optional(map(string), {})
    service_account_name             = optional(string, "default")
    automount_service_account_token  = optional(bool, true)
    restart_policy                   = optional(string, "Always")
    termination_grace_period_seconds = optional(number, 30)
    dns_policy                       = optional(string, "ClusterFirst")
    strategy_type                    = optional(string, "RollingUpdate")
    max_surge                        = optional(string, "25%")
    max_unavailable                  = optional(string, "25%")
    revision_history_limit           = optional(number, 10)
    min_ready_seconds                = optional(number, 0)
    progress_deadline_seconds        = optional(number, 600)

    containers = list(object({
      name              = string
      image             = string
      image_pull_policy = optional(string, "IfNotPresent")

      ports = optional(list(object({
        name           = string
        container_port = number
        protocol       = optional(string, "TCP")
      })), [])

      env = optional(list(object({
        name  = string
        value = string
      })), [])

      env_from = optional(list(object({
        config_map_name = string
      })), [])

      volume_mounts = optional(list(object({
        name       = string
        mount_path = string
        read_only  = optional(bool, false)
      })), [])

      resources = optional(object({
        limits = optional(map(string), {
          cpu    = "250m"
          memory = "256Mi"
        })
        requests = optional(map(string), {
          cpu    = "100m"
          memory = "128Mi"
        })
      }), null)

      liveness_probe = optional(object({
        initial_delay_seconds = optional(number, 10)
        period_seconds        = optional(number, 10)
        timeout_seconds       = optional(number, 1)
        success_threshold     = optional(number, 1)
        failure_threshold     = optional(number, 3)

        http_get = optional(object({
          path   = string
          port   = string
          scheme = optional(string, "HTTP")
        }), null)

        exec = optional(object({
          command = list(string)
        }), null)
      }), null)

      readiness_probe = optional(object({
        initial_delay_seconds = optional(number, 5)
        period_seconds        = optional(number, 10)
        timeout_seconds       = optional(number, 1)
        success_threshold     = optional(number, 1)
        failure_threshold     = optional(number, 3)

        http_get = optional(object({
          path   = string
          port   = string
          scheme = optional(string, "HTTP")
        }), null)

        exec = optional(object({
          command = list(string)
        }), null)
      }), null)

      security_context = optional(object({
        allow_privilege_escalation = optional(bool, false)
        privileged                 = optional(bool, false)
        read_only_root_filesystem  = optional(bool, false)
        run_as_non_root            = optional(bool, false)
        run_as_user                = optional(number, null)
      }), null)
    }))

    volumes = optional(list(object({
      name = string

      config_map = optional(object({
        name = string
      }), null)

      secret = optional(object({
        secret_name = string
      }), null)

      persistent_volume_claim = optional(object({
        claim_name = string
      }), null)

      empty_dir        = optional(bool, false)
      empty_dir_medium = optional(string, "")
    })), [])
  }))
  default = {}
}

variable "services_production" {
  description = "Kubernetes Services to create"
  type = map(object({
    type             = optional(string, "ClusterIP")
    selector         = map(string)
    labels           = optional(map(string), {})
    annotations      = optional(map(string), {})
    session_affinity = optional(string, "None")

    ports = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = optional(string, "TCP")
    }))
  }))
  default = {}
}

variable "ingress_resources_production" {
  description = "Ingress rules for production environment"
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
  default = {
    default = {
      annotations = {}
      rules = [
        {
          host = "production.local"
          paths = [
            {
              path         = "/"
              path_type    = "Prefix"
              service_name = "default-service"
              service_port = 80
            }
          ]
        }
      ]
      tls = null
    }
  }
}

variable "enable_prometheus_production" {
  description = "Whether to deploy Prometheus stack in production environment"
  type        = bool
  default     = false
}

variable "enable_grafana_production" {
  description = "Whether to deploy Grafana in production environment"
  type        = bool
  default     = false
}

variable "create_monitoring_namespace_production" {
  description = "Whether to create the monitoring namespace in production environment"
  type        = bool
  default     = false
}
