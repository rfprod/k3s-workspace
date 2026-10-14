locals {
  frontend_apps = { for name, app in var.apps : name => app if app.app_type == "frontend" }
  backend_apps  = { for name, app in var.apps : name => app if app.app_type == "backend" }
}

resource "kubernetes_ingress_v1" "apps" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name      = "app-ingress"
    namespace = kubernetes_namespace.app_namespaces["nx-ng-app"].metadata[0].name
  }

  spec {
    # Frontend rules with subdomains
    dynamic "rule" {
      for_each = local.frontend_apps

      content {
        host = "${rule.key}.localhost"

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = rule.key
                port {
                  number = rule.value.ports["http"] # Route to "http" port
                }
              }
            }
          }
        }
      }
    }

    # Backend API rules with path-based routing
    dynamic "rule" {
      for_each = local.backend_apps

      content {
        host = "localhost"

        http {
          # HTTP API endpoint
          path {
            path      = "/api/${rule.key}"
            path_type = "Prefix"

            backend {
              service {
                name = rule.key
                port {
                  number = rule.value.ports["http"] # Route to "http" port
                }
              }
            }
          }

          # WebSocket endpoint (if it exists)
          dynamic "path" {
            for_each = contains(keys(rule.value.ports), "websocket") ? [1] : []

            content {
              path      = "/api/${rule.key}/ws"
              path_type = "Prefix"

              backend {
                service {
                  name = rule.key
                  port {
                    number = rule.value.ports["websocket"] # Route to "websocket" port
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.apps]
}
