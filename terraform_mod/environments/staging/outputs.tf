output "kubeconfig_context" {
  description = "Kubernetes context in use"
  value       = var.kubeconfig_context
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = var.kubeconfig_path
}

output "staging_namespace" {
  description = "Staging namespace"
  value       = module.staging_namespace.namespace_name
}

output "ingress_info" {
  description = "Ingress configuration for staging environment"
  value       = var.ingress_resources_staging
}

output "local_access_guide" {
  description = "Guide to access staging services"
  value       = <<-EOT
    To access staging services locally, add these to /etc/hosts:

    127.0.0.1 staging.local
    127.0.0.1 api.staging.local

    Then visit:
    - http://staging.local (Web application)
    - http://api.staging.local (API service)

    For monitoring (if enabled):
    kubectl port-forward -n monitoring svc/grafana 3000:80
    - Grafana: http://localhost:3000
  EOT
}

# output "pvc_details" {
#   description = "PersistentVolumeClaim details"
#   value       = module.staging_storage.persistent_volume_claims
# }

output "networking_ingress_endpoints" {
  description = "Ingress endpoints configured"
  value       = try(module.staging_networking.ingress_endpoints, {})
}

output "storage_summary" {
  description = "Storage configuration summary"
  value = {
    storage_class = "local-path"
    pvcs          = keys(var.pvc_configs_staging)
    total_size    = join(", ", [for k, v in var.pvc_configs_staging : "${k}=${v.size}"])
  }
}

output "monitoring_namespace_created" {
  description = "Whether monitoring namespace is created"
  value       = var.create_monitoring_namespace_staging
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enable_prometheus_staging
}

output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = var.enable_grafana_staging
}

output "environment_summary" {
  description = "Summary of staging environment setup"
  value = {
    namespace   = module.staging_namespace.namespace_name
    context     = var.kubeconfig_context
    environment = var.environment
    monitoring  = var.create_monitoring_namespace_staging
    prometheus  = var.enable_prometheus_staging
    grafana     = var.enable_grafana_staging
  }
}
