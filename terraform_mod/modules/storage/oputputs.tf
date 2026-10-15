# output "storage_class_names" {
#   description = "Names of created StorageClasses"
#   value       = keys(kubernetes_storage_class.this)
# }

output "persistent_volume_claims" {
  description = "Created PersistentVolumeClaims"
  value = {
    for name, pvc in kubernetes_persistent_volume_claim.this :
    name => {
      name      = pvc.metadata[0].name
      namespace = pvc.metadata[0].namespace
      size      = pvc.spec[0].resources[0].requests.storage
    }
  }
}
