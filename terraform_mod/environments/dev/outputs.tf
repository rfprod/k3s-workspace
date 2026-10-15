output "kubeconfig_context" {
  description = "Kubernetes context in use"
  value       = var.kubeconfig_context
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = var.kubeconfig_path
}

output "dev_namespace" {
  description = "Development namespace"
  value       = module.dev_namespace.namespace_name
}

output "ingress_info" {
  description = "Ingress configuration for dev environment"
  value       = var.ingress_resources_dev
}

output "local_access_guide" {
  description = "Guide to access local services"
  value       = <<-EOT
    To access dev services locally, add these to /etc/hosts:

    127.0.0.1 dev.local
    127.0.0.1 api.dev.local

    Then visit:
    - http://dev.local (Web application)
    - http://api.dev.local (API service)

    For monitoring (if enabled):
    kubectl port-forward -n monitoring svc/grafana 3000:80
    - Grafana: http://localhost:3000
  EOT
}

# output "pvc_details" {
#   description = "PersistentVolumeClaim details"
#   value       = module.dev_storage.persistent_volume_claims
# }

output "networking_ingress_endpoints" {
  description = "Ingress endpoints configured"
  value       = try(module.dev_networking.ingress_endpoints, {})
}

output "storage_summary" {
  description = "Storage configuration summary"
  value = {
    storage_class = "local-path"
    pvcs          = keys(var.pvc_configs_dev)
    total_size    = join(", ", [for k, v in var.pvc_configs_dev : "${k}=${v.size}"])
  }
}

output "monitoring_namespace_created" {
  description = "Whether monitoring namespace is created"
  value       = var.create_monitoring_namespace_dev
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enable_prometheus_dev
}

output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = var.enable_grafana_dev
}

output "environment_summary" {
  description = "Summary of dev environment setup"
  value = {
    namespace   = module.dev_namespace.namespace_name
    context     = var.kubeconfig_context
    environment = var.environment
    monitoring  = var.create_monitoring_namespace_dev
    prometheus  = var.enable_prometheus_dev
    grafana     = var.enable_grafana_dev
  }
}
