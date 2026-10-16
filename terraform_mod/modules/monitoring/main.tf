# Create namespace for monitoring
resource "kubernetes_namespace_v1" "monitoring" {
  count = var.create_monitoring_namespace ? 1 : 0

  metadata {
    name = var.monitoring_namespace
    labels = merge(
      var.labels,
      {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    )
  }
}

# Deploy Prometheus Stack
resource "helm_release" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.prometheus_version
  namespace        = var.monitoring_namespace
  create_namespace = false

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "10d"
          resources = {
            requests = {
              cpu    = "100m"
              memory = " 128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    })
  ]

  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  cleanup_on_fail   = true
  dependency_update = true

  depends_on = [kubernetes_namespace_v1.monitoring]
}

# Deploy Grafana
resource "helm_release" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_version
  namespace        = var.monitoring_namespace
  create_namespace = false

  values = [
    yamlencode({
      adminPassword = var.grafana_admin_password
      persistence = {
        accessModes          = ["ReadWriteOnce"]
        enabled              = true
        initChownRecursively = true
        labels               = { "app" = "grafana" }
        size                 = "3Gi"
        storageClassName     = "local-path"
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    })
  ]

  wait              = true
  wait_for_jobs     = true
  timeout           = 600
  cleanup_on_fail   = true
  dependency_update = true

  depends_on = [kubernetes_namespace_v1.monitoring]
}

# Create ServiceMonitor for application monitoring (optional)
resource "kubernetes_manifest" "prometheus_service_monitor" {
  for_each = var.enable_prometheus && var.service_monitors != null ? var.service_monitors : {}

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = each.key
      namespace = var.monitoring_namespace
      labels    = var.labels
    }
    spec = each.value
  }

  depends_on = [helm_release.prometheus]
}

# Create PrometheusRule for alerting (optional)
resource "kubernetes_manifest" "prometheus_rule" {
  for_each = var.enable_prometheus && var.prometheus_rules != null ? var.prometheus_rules : {}

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = each.key
      namespace = var.monitoring_namespace
      labels    = var.labels
    }
    spec = each.value
  }

  depends_on = [helm_release.prometheus]
}

# Create Ingress for Prometheus
resource "kubernetes_ingress_v1" "prometheus" {
  count = var.enable_prometheus && var.expose_prometheus ? 1 : 0

  metadata {
    name      = "prometheus"
    namespace = var.monitoring_namespace
    labels    = var.labels

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = var.prometheus_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "prometheus-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.prometheus_hostname]
      secret_name = "prometheus-tls"
    }
  }

  depends_on = [helm_release.prometheus]
}

# Create Ingress for Grafana
resource "kubernetes_ingress_v1" "grafana" {
  count = var.enable_grafana && var.expose_grafana ? 1 : 0

  metadata {
    name      = "grafana"
    namespace = var.monitoring_namespace
    labels    = var.labels

    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = var.grafana_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.grafana_hostname]
      secret_name = "grafana-tls"
    }
  }

  depends_on = [helm_release.grafana]
}
