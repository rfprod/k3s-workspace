locals {
  namespaces = toset([for app in var.apps : app.namespace])
}

resource "kubernetes_namespace" "app_namespaces" {
  for_each = local.namespaces

  metadata {
    name = each.value
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
