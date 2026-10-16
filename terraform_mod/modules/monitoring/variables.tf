variable "labels" {
  description = "Common labels to apply to all monitoring resources"
  type        = map(string)
  default = {
    environment = "local"
    managed_by  = "terraform"
  }
}

variable "create_monitoring_namespace" {
  description = "Whether to create the monitoring namespace"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "enable_prometheus" {
  description = "Whether to deploy Prometheus stack"
  type        = bool
  default     = true
}

variable "prometheus_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "57.0.0"
}

variable "prometheus_set_values" {
  description = "Additional Helm set values for Prometheus"
  type        = map(string)
  default = {
    "prometheus.prometheusSpec.retention"                                                       = "10d"
    "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"             = "ReadWriteOnce"
    "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage" = "5Gi"
  }
}

variable "enable_grafana" {
  description = "Whether to deploy Grafana"
  type        = bool
  default     = true
}

variable "grafana_version" {
  description = "Version of Grafana Helm chart"
  type        = string
  default     = "7.0.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "grafana_set_values" {
  description = "Additional Helm set values for Grafana"
  type        = map(string)
  default = {
    "persistence.enabled" = "true"
    "persistence.size"    = "5Gi"
    "adminUser"           = "admin"
  }
}

variable "expose_prometheus" {
  description = "Whether to expose Prometheus via Ingress"
  type        = bool
  default     = false
}

variable "prometheus_hostname" {
  description = "Hostname for Prometheus Ingress"
  type        = string
  default     = "prometheus.local"
}

variable "expose_grafana" {
  description = "Whether to expose Grafana via Ingress"
  type        = bool
  default     = true
}

variable "grafana_hostname" {
  description = "Hostname for Grafana Ingress"
  type        = string
  default     = "grafana.local"
}

variable "service_monitors" {
  description = "ServiceMonitor resources for Prometheus scraping"
  type = map(object({
    selector = optional(object({
      matchLabels = optional(map(string), {})
    }))
    endpoints = optional(list(object({
      port     = optional(string)
      path     = optional(string, "/metrics")
      interval = optional(string, "30s")
    })))
  }))
  default = {}
}

variable "prometheus_rules" {
  description = "PrometheusRule resources for alerting"
  type        = any
  default     = {}
}

variable "ingress_class" {
  description = "Ingress class name for Prometheus and Grafana"
  type        = string
  default     = "traefik"
}

variable "cert_issuer" {
  description = "cert-manager ClusterIssuer name"
  type        = string
  default     = "letsencrypt-staging"
}
