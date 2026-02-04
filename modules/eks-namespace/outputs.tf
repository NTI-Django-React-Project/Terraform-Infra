output "namespace_names" {
  description = "Map of namespace keys to actual namespace names"
  value       = { for k, v in kubernetes_namespace_v1.this : k => v.metadata[0].name }
}

output "namespace_details" {
  description = "Detailed information about created namespaces"
  value = { for k, v in kubernetes_namespace_v1.this : k => {
    name        = v.metadata[0].name
    uid         = v.metadata[0].uid
    labels      = v.metadata[0].labels
    annotations = v.metadata[0].annotations
  }}
  sensitive = false
}