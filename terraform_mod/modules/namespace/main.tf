# Create Kubernetes namespace with RBAC
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace_name
    labels = merge(
      var.labels,
      {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    )
  }
}

# The `default` service account is cluster-manged.
# Create ServiceAccount for the namespace
# resource "kubernetes_service_account" "this" {
#   metadata {
#     name      = var.service_account_name
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#     labels    = var.labels
#   }
# }

# Create ClusterRole for read-only access (optional)
resource "kubernetes_cluster_role" "read_only" {
  count = var.create_read_only_role ? 1 : 0

  metadata {
    name   = "${var.namespace_name}-read-only"
    labels = var.labels
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }
}

# Bind ClusterRole to ServiceAccount
# resource "kubernetes_cluster_role_binding" "read_only" {
#   count = var.create_read_only_role ? 1 : 0

#   metadata {
#     name   = "${var.namespace_name}-read-only-binding"
#     labels = var.labels
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.read_only[0].metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.this.metadata[0].name
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#   }
# }

# Create Role for namespace-specific admin access (optional)
resource "kubernetes_role" "admin" {
  count = var.create_admin_role ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-admin"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = var.labels
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# Bind Role to ServiceAccount
# resource "kubernetes_role_binding" "admin" {
#   count = var.create_admin_role ? 1 : 0

#   metadata {
#     name      = "${var.namespace_name}-admin-binding"
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#     labels    = var.labels
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "Role"
#     name      = kubernetes_role.admin[0].metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.this.metadata[0].name
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#   }
# }

# Create Network Policy to deny all ingress by default (optional)
resource "kubernetes_network_policy" "default_deny" {
  count = var.create_network_policy ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-default-deny-ingress"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = var.labels
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Create ResourceQuota for the namespace (optional)
resource "kubernetes_resource_quota" "this" {
  count = var.resource_quota_enabled ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-quota"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
    labels    = var.labels
  }

  spec {
    hard = var.resource_quota_limits
  }
}
