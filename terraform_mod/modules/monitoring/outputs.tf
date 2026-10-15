# Monitoring Namespace
output "monitoring_namespace" {
  description = "Name of the monitoring namespace"
  value       = var.create_monitoring_namespace ? kubernetes_namespace_v1.monitoring[0].metadata[0].name : var.monitoring_namespace
}

# Prometheus Outputs
output "prometheus_release" {
  description = "Prometheus Helm release details"
  value = var.enable_prometheus ? {
    id        = helm_release.prometheus[0].id
    name      = helm_release.prometheus[0].name
    chart     = helm_release.prometheus[0].chart
    version   = helm_release.prometheus[0].version
    status    = helm_release.prometheus[0].status
    namespace = helm_release.prometheus[0].namespace
  } : null
  sensitive = false
}

output "prometheus_service_name" {
  description = "Kubernetes service name for Prometheus"
  value       = var.enable_prometheus ? "prometheus-kube-prometheus-prometheus" : null
}

output "prometheus_service_port" {
  description = "Kubernetes service port for Prometheus"
  value       = var.enable_prometheus ? 9090 : null
}

output "prometheus_hostname" {
  description = "Prometheus hostname (from ingress)"
  value       = var.enable_prometheus && var.expose_prometheus ? var.prometheus_hostname : null
}

output "prometheus_ingress_url" {
  description = "Prometheus Ingress URL"
  value       = var.enable_prometheus && var.expose_prometheus ? "https://${var.prometheus_hostname}" : null
}

output "prometheus_tls_secret" {
  description = "TLS secret name for Prometheus Ingress"
  value       = var.enable_prometheus && var.expose_prometheus ? kubernetes_ingress_v1.prometheus[0].spec[0].tls[0].secret_name : null
}

# Grafana Outputs
output "grafana_release" {
  description = "Grafana Helm release details"
  value = var.enable_grafana ? {
    id        = helm_release.grafana[0].id
    name      = helm_release.grafana[0].name
    chart     = helm_release.grafana[0].chart
    version   = helm_release.grafana[0].version
    status    = helm_release.grafana[0].status
    namespace = helm_release.grafana[0].namespace
  } : null
  sensitive = false
}

output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = var.enable_grafana ? "grafana" : null
}

output "grafana_service_port" {
  description = "Kubernetes service port for Grafana"
  value       = var.enable_grafana ? 80 : null
}

output "grafana_hostname" {
  description = "Grafana hostname (from ingress)"
  value       = var.enable_grafana && var.expose_grafana ? var.grafana_hostname : null
}

output "grafana_ingress_url" {
  description = "Grafana Ingress URL"
  value       = var.enable_grafana && var.expose_grafana ? "https://${var.grafana_hostname}" : null
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.enable_grafana ? "admin" : null
}

output "grafana_tls_secret" {
  description = "TLS secret name for Grafana Ingress"
  value       = var.enable_grafana && var.expose_grafana ? kubernetes_ingress_v1.grafana[0].spec[0].tls[0].secret_name : null
}

output "service_monitors" {
  description = "Deployed ServiceMonitor resources"
  value = {
    for key, monitor in kubernetes_manifest.prometheus_service_monitor : key => {
      name      = monitor.manifest.metadata.name
      namespace = monitor.manifest.metadata.namespace
      kind      = monitor.manifest.kind
    }
  }
}

output "prometheus_rules" {
  description = "Deployed PrometheusRule resources"
  value = {
    for key, rule in kubernetes_manifest.prometheus_rule : key => {
      name      = rule.manifest.metadata.name
      namespace = rule.manifest.metadata.namespace
      kind      = rule.manifest.kind
    }
  }
}

output "access_info" {
  description = "Summary of monitoring stack access information"
  value = {
    prometheus = var.enable_prometheus ? {
      enabled  = true
      internal = "http://${var.enable_prometheus ? "prometheus-kube-prometheus-prometheus" : null}:9090"
      external = var.expose_prometheus ? "https://${var.prometheus_hostname}" : "Not exposed"
      } : {
      enabled = false
    }
    grafana = var.enable_grafana ? {
      enabled    = true
      internal   = "http://${var.enable_grafana ? "grafana" : null}:80"
      external   = var.expose_grafana ? "https://${var.grafana_hostname}" : "Not exposed"
      admin_user = "admin"
      } : {
      enabled = false
    }
  }
}
