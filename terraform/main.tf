output "namespaces" {
  value       = local.namespaces
  description = "Created namespaces"
}

output "deployments" {
  value = {
    for name, app in kubernetes_deployment.apps :
    name => {
      namespace = app.metadata[0].namespace
      replicas  = app.spec[0].replicas
    }
  }
  description = "Deployed applications"
}

output "services" {
  value = {
    for name, svc in kubernetes_service.apps :
    name => {
      namespace = svc.metadata[0].namespace
      port      = svc.spec[0].port[0].port
      dns_name  = "${svc.metadata[0].name}.${svc.metadata[0].namespace}.svc.cluster.local"
    }
  }
  description = "Service DNS names (use within cluster)"
}

output "ingress_hosts" {
  value = var.ingress_enabled ? {
    for name in keys(local.frontend_apps) :
    name => "${name}.localhost"
  } : {}
  description = "Frontend app hosts (add to /etc/hosts)"
}
