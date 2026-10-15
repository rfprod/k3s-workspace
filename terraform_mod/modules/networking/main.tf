# Create Ingress resources
resource "kubernetes_ingress_v1" "this" {
  for_each = var.ingress_resources

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels    = var.labels

    annotations = merge(
      var.ingress_annotations,
      each.value.annotations != null ? each.value.annotations : {}
    )
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = each.value.rules
      content {
        host = rule.value.host
        http {
          dynamic "path" {
            for_each = rule.value.paths
            content {
              path      = path.value.path
              path_type = path.value.path_type

              backend {
                service {
                  name = path.value.service_name
                  port {
                    number = path.value.service_port
                  }
                }
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = each.value.tls != null ? [each.value.tls] : []
      content {
        hosts       = tls.value.hosts
        secret_name = tls.value.secret_name
      }
    }
  }
}

# Create NetworkPolicy resources (optional)
resource "kubernetes_network_policy" "this" {
  for_each = var.network_policies

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels    = var.labels
  }

  spec {
    pod_selector {
      match_labels = each.value.pod_selector_labels
    }

    policy_types = each.value.policy_types

    dynamic "ingress" {
      for_each = each.value.ingress_rules != null ? each.value.ingress_rules : []
      content {
        dynamic "from" {
          for_each = ingress.value.from != null ? ingress.value.from : []
          content {
            dynamic "pod_selector" {
              for_each = from.value.pod_selector != null ? [from.value.pod_selector] : []
              content {
                match_labels = pod_selector.value.match_labels
              }
            }

            dynamic "namespace_selector" {
              for_each = from.value.namespace_selector != null ? [from.value.namespace_selector] : []
              content {
                match_labels = namespace_selector.value.match_labels
              }
            }
          }
        }

        dynamic "ports" {
          for_each = ingress.value.ports != null ? ingress.value.ports : []
          content {
            protocol = ports.value.protocol
            port     = ports.value.port
          }
        }
      }
    }

    dynamic "egress" {
      for_each = each.value.egress_rules != null ? each.value.egress_rules : []
      content {
        dynamic "to" {
          for_each = egress.value.to != null ? egress.value.to : []
          content {
            dynamic "pod_selector" {
              for_each = to.value.pod_selector != null ? [to.value.pod_selector] : []
              content {
                match_labels = pod_selector.value.match_labels
              }
            }

            dynamic "namespace_selector" {
              for_each = to.value.namespace_selector != null ? [to.value.namespace_selector] : []
              content {
                match_labels = namespace_selector.value.match_labels
              }
            }
          }
        }

        dynamic "ports" {
          for_each = egress.value.ports != null ? egress.value.ports : []
          content {
            protocol = ports.value.protocol
            port     = ports.value.port
          }
        }
      }
    }
  }
}
