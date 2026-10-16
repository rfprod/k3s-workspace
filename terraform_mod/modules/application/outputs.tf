output "deployments" {
  description = "Created Deployments"
  value = {
    for name, deployment in kubernetes_deployment_v1.this :
    name => {
      name            = deployment.metadata[0].name
      namespace       = deployment.metadata[0].namespace
      replicas        = deployment.spec[0].replicas
      selector_labels = deployment.spec[0].selector[0].match_labels
    }
  }
}

output "services" {
  description = "Created Services"
  value = {
    for name, service in kubernetes_service_v1.this :
    name => {
      name       = service.metadata[0].name
      namespace  = service.metadata[0].namespace
      type       = service.spec[0].type
      cluster_ip = service.spec[0].cluster_ip
      ports = [
        for port in service.spec[0].port : {
          name        = port.name
          port        = port.port
          target_port = port.target_port
          protocol    = port.protocol
        }
      ]
    }
  }
}

output "config_maps" {
  description = "Created ConfigMaps"
  value = {
    for name, config_map in kubernetes_config_map_v1.this :
    name => {
      name      = config_map.metadata[0].name
      namespace = config_map.metadata[0].namespace
    }
  }
}

output "secrets" {
  description = "Created Secrets"
  value = {
    for name, secret in kubernetes_secret_v1.this :
    name => {
      name      = secret.metadata[0].name
      namespace = secret.metadata[0].namespace
      type      = secret.type
    }
  }
  sensitive = true
}
