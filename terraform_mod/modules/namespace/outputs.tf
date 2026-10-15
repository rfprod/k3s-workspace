output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

# output "service_account_name" {
#   description = "Name of the created ServiceAccount"
#   value       = kubernetes_service_account.this.metadata[0].name
# }

output "namespace_uid" {
  description = "UID of the created namespace"
  value       = kubernetes_namespace_v1.this.metadata[0].uid
}
