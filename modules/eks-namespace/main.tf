locals {
  # Merge default labels with custom labels
  namespace_configs = { for k, v in var.namespaces : k => {
    name        = v.name
    labels      = merge(var.create_default_labels ? var.default_labels : {}, v.labels)
    annotations = v.annotations
  }}
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespace_configs

  metadata {
    name        = each.value.name
    labels      = each.value.labels
    annotations = each.value.annotations
  }

  lifecycle {
    prevent_destroy = false
    # Ignore label/annotation changes that might be added by other tools
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations
    ]
  }
}

resource "kubernetes_limit_range_v1" "default" {
  for_each = { for k, v in local.namespace_configs : k => v 
    if v.name != "kube-system" && v.name != "default"
  }

  metadata {
    name      = "default-resource-limits"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = "1500m"
        memory = "6Gi"
      }

      default_request = {
        cpu    = "1000m"
        memory = "4Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.this]
}