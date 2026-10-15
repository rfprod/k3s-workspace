output "ingress_resources" {
  description = "Created Ingress resources"
  value = {
    for name, ingress in kubernetes_ingress_v1.this :
    name => {
      name      = ingress.metadata[0].name
      namespace = ingress.metadata[0].namespace
      hosts = flatten([
        for rule in ingress.spec[0].rule :
        rule.host
      ])
    }
  }
}

output "network_policies" {
  description = "Created NetworkPolicy resources"
  value = {
    for name, policy in kubernetes_network_policy.this :
    name => {
      name      = policy.metadata[0].name
      namespace = policy.metadata[0].namespace
    }
  }
}
