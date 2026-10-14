resource "kubernetes_deployment" "apps" {
  for_each = var.apps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.app_namespaces[each.value.namespace].metadata[0].name

    labels = {
      app      = each.key
      app_type = each.value.app_type
    }
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = {
        app = each.key
      }
    }

    template {
      metadata {
        labels = {
          app = each.key
        }
        annotations = {
          "deployment.kubernetes.io/timestamp" = timestamp()
        }

      }

      spec {
        container {
          name              = each.key
          image             = "${each.value.image}:${each.value.tag}"
          image_pull_policy = "Always"

          # Support multiple ports per container
          dynamic "port" {
            for_each = each.value.ports
            content {
              name           = port.key
              container_port = port.value
              protocol       = "TCP"
            }
          }

          # Environment variables
          dynamic "env" {
            for_each = each.value.environment
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.app_namespaces]
}

# Create services for each app
resource "kubernetes_service" "apps" {
  for_each = var.apps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.app_namespaces[each.value.namespace].metadata[0].name
  }

  spec {
    selector = {
      app = each.key
    }

    # Support multiple ports per service
    dynamic "port" {
      for_each = each.value.ports
      content {
        name        = port.key
        port        = port.value
        target_port = port.value
        protocol    = "TCP"
      }
    }

    type = each.value.app_type == "frontend" ? "ClusterIP" : "ClusterIP"
  }

  depends_on = [kubernetes_deployment.apps]
}
