# Create StorageClass (local k3s uses local-path by default, but allows customization)
# resource "kubernetes_storage_class" "this" {
#   for_each = var.storage_classes

#   metadata {
#     name   = each.key
#     labels = var.labels
#   }

#   storage_provisioner    = each.value.provisioner
#   reclaim_policy         = each.value.reclaim_policy
#   allow_volume_expansion = each.value.allow_volume_expansion
#   parameters             = each.value.parameters

#   volume_binding_mode = each.value.volume_binding_mode
# }

# Create PersistentVolumeClaim for application storage
resource "kubernetes_persistent_volume_claim" "this" {
  for_each = var.persistent_volume_claims

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels    = var.labels
  }

  spec {
    access_modes       = each.value.access_modes
    storage_class_name = each.value.storage_class
    resources {
      requests = {
        storage = each.value.size
      }
    }
  }

  depends_on = []
  # depends_on = [kubernetes_storage_class.this]
}
