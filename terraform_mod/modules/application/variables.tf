variable "namespace_name" {
  description = "Kubernetes namespace where applications will be deployed"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to all application resources"
  type        = map(string)
  default = {
    environment = "local"
    managed_by  = "terraform"
  }
}

variable "deployments" {
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

variable "services" {
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

variable "config_maps" {
  description = "Kubernetes ConfigMaps to create"
  type = map(object({
    data = map(string)
  }))
  default = {}
}

variable "secrets" {
  description = "Kubernetes Secrets to create"
  type = map(object({
    type = optional(string, "Opaque")
    name = string
    data = map(string)
  }))
  default   = {}
  sensitive = true
}
